###
 *  
 * This class controls all the player details like their socket and stats
 *
###
netMsg = require 'config/net-messages'
config = require 'config/general'
gameMsg = require 'config/game-messages'
bulkLoad = require("config/bulk-load")
minionConfig = bulkLoad("minions") 
tdb = require('../../database')
rs = require 'randomstring'
serverConfig = require 'config/gameserver'
User = tdb.models.User
log = require('logger')
_ = require("lodash");
oberr = require("oberr");

class Player
  id: null
  socket: null
  game: null      #A pointer to the game the player is currently in
  name: "Unnamed"
  race: null
  team: 0
  isBot: false
  token: null
  state: config.states.none
  disconnected: false;
  currentTick: 0;
  oldestUnconfirmedTick: 0;  #Keep track of the oldest tick was confirmed so we don't send too many ticks in advance (queues them instead)
  tickSendQueue: {}        #We don't want to have more than 10 pending ticks to the player at a time so if they lag they don't get tick spammed.
  tickConfirmsToCheck: {}  #Tick ID's that have yet to be confirmed by the player, resend them until they have been sent. 
  lastConfirmDelays: []    #Number of ticks to confirm for the last 10 ticks so that we can average it out and only send unconfirmed ticks after this much time has passed
  ping: 0
  ready: false
  loaded: false
  log: null
  gameLog: null
  lastAction: null

  constructor: () ->
    @log = log
    @reset()
    @state = config.states.init;

  reset: ->
    @socket = null
    @game = null
    @name = "Unnamed"
    @race = null
    @team = 0
    @isBot = false
    @token = null
    @state = config.states.none
    @disconnected = false
    @currentTick = 0
    @oldestUnconfirmedTick = 0
    @tickSendQueue = {}
    @tickConfirmsToCheck = {}
    @lastConfirmDelays = []
    @ping = 0
    @ready = false
    @loaded = false

  ###
   * Return basic player details in an object
  ###
  getDetails: =>
    {
      @id,
      @name,
      @race,
      @minions
    }

  sendDetails: =>
    playerDetails = @getDetails()
    if @game.get('state') == config.states.begun
      playerDetails.sync = true
    @socket.emit netMsg.player.details, playerDetails

  setState: (state) =>
    @state = state;

  isLoaded: =>
    return @state == config.states.begun;

  init: (@id) =>
    @bindFunctions()

  setSocket: (socket) =>
    if @socket
      delete @socket
    @socket = socket;

  joinGame: (@game) =>
    @log = new (log.Logger)({
      transports: log.getCustomTransports('gameserver', [@game.get("code")])
    })
    @log.info("Player joining game")
    @disconnected = false;
    @bindGameSockets(@game);
    @gameLog = new (log.Logger)({
      transports: [new (log.transports.File)({ filename: serverConfig.logDir + '/game-logs-client/' + @game.code + '-' + @id + '.log', timestamp: false})]
    })

  kick: () =>
    if @disconnected
      return false
    @socket.emit netMsg.game.kicked


  syncData: () =>
    @log.info("Sending syncdata to player")
    currentTick = @game.getCurrentTick()
    data = {}
    data.ticks = @game.getTicks()
    data.settings = @game.get('settings')
    data.playerId = @id
    data.players = @game.getPlayers()
    @log.info("Sending sync data: ", data);
    @log.info("Sending currnet tick: " + currentTick + " ticks: ", data.ticks);
    @socket.emit netMsg.game.syncData, currentTick, data

  setRace: (race) =>
    @race = race
    return true
    
  setMinions: (minions) =>
    @minions = @removeInvalidMinions(_.uniq(minions))
    return true
    
  removeInvalidMinions: (minions) =>
    return minions.filter((m) => return !!minionConfig[m])

  getRace: =>
    return @race

  setTeam: (team) =>
    if isNaN(team)
      return false;
    @team = team
    return true

  getTeam: =>
    return @team

  setIsBot: (isBot) =>
    @isBot = isBot
    return true

  setReady: (ready) =>
    @ready = ready
    return true

  setLoaded: (loaded) =>
    @loaded = loaded
    return true

  # Closes player socket, though currently there is one player object for lobby and one for
  # each game when you join games. This will need to be fixed in the future when just the one
  # player object is thrown around with tokens. 
  disconnect: =>
    @log.info("Player " + @id + " is disconnecting")
    if @socket?
      @socket.disconnect()
    @disconnected = true

  bindFunctions: =>
    if !@socket
      return false;
    socket = @socket
    playerId = @id
    lobbyPath = "/lobby"

  #Check if the players username has changed and if so set it to the new value
  reloadName: (callback) =>
    @log.info("In reload name", {code: @game.code})
    User.findById @id, (err, user) =>
      @log.info("In reload name got user: ", user, {code: @game.code})
      if err then callback(err, null)
      @name = user.get('username')
      @log.info "Calling back with new name", {code: @game.code}
      callback(null, @name)

  addConfirmTime: (sendTick, confirmTick) =>
    if @lastConfirmDelays.length > 10
      @lastConfirmDelays.splice 0, 1
    confirmDelay = confirmTick - sendTick
    @lastConfirmDelays.push confirmDelay
    # @log.info "Adding confirm delay of sendTick: ", sendTick, "confirm tick: ", confirmTick, "delay", confirmDelay

  calculatePing: (averageDelayTime) =>
    if !@game?
      return false
    if !averageDelayTime?
      averageDelayTime = @getResendDelay();
    @ping = (averageDelayTime * @game.ts.Timer.constantStep) * 1000

  sendPing: =>    
    @socket.emit netMsg.player.pingTime, @ping;

  sendTick: (tick, commandsDone) =>   
    if @disconnected
      return false
#    @log.info "Sending tick ", tick, " commands: ", commandsDone
    if serverConfig.addLag
      lag = Math.round(Math.random()*5000)
      setTimeout =>
        @socket.emit netMsg.game.tickData, tick, commandsDone, (data) =>
      , lag
    else
      @socket.emit netMsg.game.tickData, tick, commandsDone, (data) =>

  checkHash: (tick, hash, callback) =>
    if !@game?
      return false
    if @game.getMode() == "TUTORIAL"
      return callback(JSON.stringify({ok: true}))
    if @game.gameSnapshotHash[tick]?
      callbackObject = {ok: false}
      if hash != @game.gameSnapshotHash[tick]
        callbackObject.ok = false
        @game.reportInvalidState(tick)
        @log.info("Hash Incorrect for player ", @id)
      else
        callbackObject.ok = true
      callback JSON.stringify(callbackObject)

  canPerformAction: =>
    if @state != config.states.begun   #Ignore placing towers when the game hasn't even behun yet.
      return false
    if @lastAction #Can't queue more than one action at once
      return false
    return true

  performAction: (type, data) =>
    if !@canPerformAction()
      return false
    @lastAction = {type, data}

  placeTower: (xPos, yPos, towerType) =>
    if (!towerType) then return console.error("User " + @id + " tried to place a tower without a type")
    @performAction('towers', {xPos, yPos, towerType, ownerId: @id})

  upgradeTower: (settings) =>
    @performAction('towerUpgrades', _.merge({}, settings, {ownerId: @id}));

  sellTower: (settings) =>
    @performAction('towerSales', _.merge({}, settings, {ownerId: @id}));

  placeMinion: (xPos, yPos, minionType) =>
    @performAction('minions', {xPos, yPos, ownerId: @id, minionType: minionType});

  collectGem: (gemId) =>
    @performAction('pickups', {id: gemId})

  configure: (details, callback) =>
    callback = callback || ->
    @log.info("Configuring player " + @id + " with details: " + JSON.stringify(details))
    if !details?
      return callback(new Error("No details passed to configure"));
    if details.team? && !details.ready
      @setTeam details.team
    if details.race? && !@ready
      if @game.isRaceSelected(details.race, @getTeam())
        return callback(new Error("That race is already selected"))
      if @game.get('state') != config.states.selection
        return callback(new Error("You cannot change your race now"))
      @setRace details.race
    if details.minions? && !@ready
      if details.minions.length > config.maxMinions
        return callback(new Error("You cannot select more than " + config.maxMinions + " minions"))
      @setMinions details.minions
    if details.isBot?
      @setIsBot details.isBot
    if details.ready? && @getRace()
      @setReady(true)
      @game.userReady()
    if details.loaded?
      @setLoaded details.loaded
    return callback();

  bindGameSockets: (game) =>
    if !@socket
      return false;
    @log.info("Binding player sockets")
    @game = game;
    @socket.on netMsg.game.configure, (details, callback) =>
      @game.configure details, (success) =>
        if callback?
          callback(success)

    @socket.on netMsg.player.log.debug, (message) =>
      @gameLog.info(message)

    @log.info("Binding to message ", netMsg.player.refresh)
    @socket.on netMsg.player.refresh, (callback) =>
      @log.info("Got Refresh message")
      @reloadName (err, newName) =>
        game.broadcastDetails()
        if callback?
          callback(!err)
    ###
     * Rebinding this for game so the game can resend details
     * whenever a players details change
    ###
    @socket.on netMsg.player.configure, (details, callback) =>
      callback = callback || ->
      @log.info("Configuring player #{@id} with details: ", details)
      @configure details, (err, result) =>
        if err then return callback(oberr(err))
        game.playerUpdated(@id, details);
        game.broadcastDetails();  
        return callback();
    @socket.on netMsg.game.addBot, (details, callback) =>
      lagAmount = if !serverConfig.addBotLag then 0 else Math.round(Math.random()*2000)
      setTimeout =>
        @game.addBot(details, callback);
      , lagAmount
    @socket.on netMsg.game.configureBot, (details, callback) =>
      @log.info "Configuring bot #{@id} with details: ", details
      success = @game.configureBot(@id, details)
      callback success
      return success
    @socket.on netMsg.game.kickPlayer, (playerId) =>
      @log.info "Kicking player of id ", playerId
      success = @game.kickPlayer(@id, playerId)
      return success
    @socket.on netMsg.game.start, (details, callback) =>
      game.startSelection();
      callback "{ok: true}"
    @socket.on netMsg.player.finished, (winningTeam, lastTick) =>
      @game.playerFinished(@id, winningTeam, lastTick)
    @socket.on netMsg.disconnect, =>
      @disconnected = true
      game.playerDisconnected @
      if game.get('state') == config.states.lobby
        game.deletePlayer @
    @socket.on netMsg.player.loaded, (details, callback) =>
      @log.info("Player #{@id} loaded")
      @setState config.states.begun
      game.checkPlayersAreLoaded()
      @configure {loaded: true}, (success) =>
        game.broadcastDetails();
    @socket.on netMsg.game.tickNeeded, (tick) =>
      game.resendTick(tick, @)
      
    ###
      Checks all clients have the same game hash as the server every 100ms
    ###
    @socket.on netMsg.game.checkHash, (tick, hash, callback) =>
      @checkHash(tick, hash, callback)
    @socket.on netMsg.game.placeTower, (xPos, yPos, towerType) =>
      @placeTower(xPos, yPos, towerType)
    @socket.on netMsg.game.upgradeTower, (settings) =>
      @upgradeTower(settings)
    @socket.on netMsg.game.sellTower, (settings) =>
      @sellTower(settings)
    @socket.on netMsg.game.placeMinion, (xPos, yPos, minionType) =>
      @placeMinion(xPos, yPos, minionType)
    @socket.on netMsg.game.collectGem, (gemId) =>
      @collectGem(gemId)

module.exports = Player