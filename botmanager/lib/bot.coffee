
rs = require 'randomstring'
io = require('socket.io-client')
xhr = require('socket.io-client/node_modules/xmlhttprequest');
xhrOriginal = require('xmlhttprequest');
botConfig = require 'config/botmanager'
config = require 'config/general'
netMsg = require 'config/net-messages'
gameMsg = require 'config/game-messages'
races = require("config/bulk-load")("races") 
minions = require("config/bulk-load")("minions") 
Game = require './game'
Brain = require './brains/brain'
logic = require 'config/bot-logic'
request = require 'request'
Dispatcher = require './dispatcher'
f = require './functions'
_ = require 'lodash'
rs = require 'randomstring'
netconfig = require 'config/netconfig'
cookieJars = {}
User = require('database').models.User
log = require('logger')


delay = (ms, func) -> setTimeout(func, ms)

overrideXmlHttpRequest = () ->
  xhr.XMLHttpRequest = ->
    @XMLHttpRequest = xhrOriginal.XMLHttpRequest;
    xhrOriginal.XMLHttpRequest.apply(@, arguments);
    this.setDisableHeaderCheck(true);
    openOriginal = this.open;
    this.open = (method, url, async, user, password) ->
      openOriginal.apply(this, arguments);
      urlDetails = require('url').parse(url, true)
      if !urlDetails?.query?.botId?
        throw new Error("Failed to find botId in url " + url);
      botId = urlDetails.query.botId
      if !cookieJars[botId]
        log.info("CookieJar for botId: ", botId, " does not exist")
        return false
      header = cookieJars[botId].get({url: netconfig.lobby.url}).map((cookie) ->
        return cookie.name + '=' + cookie.value;
      ).join('; ');
      this.setRequestHeader('cookie', header);
    return @

class Bot
  id: 0
  name: null
  race: null
  minions: []
  team: 1
  fakePerson: false   #If this bot is pretending to be a real person
  pickingRace: false

  gameState: config.states.none

  startTime: 0
  lastTick: 0

  cookieJar: null
  sessionId: null
  gameKey: null
  lobbyId: null
  queuerId: null
  lastQueuerState: null
  internalState: null

  dispatcher: null
  game: null
  brain: null
  player: null
  players: {}
  socket: null
  lobbySocket: null

  constructor: ->
    @id = 0
    @trackId = rs.generate(8)
    @log = new (log.Logger)({
      transports: log.getCustomTransports('botmanager', [@trackId])
    })
    @log.info("Calling bot constructor")
    @name = null
    @race = null
    @pickingRace = false
    @team = 1
    @gameState = config.states.none
    @startTime = 0
    @lastTick = 0
    @cookieJar = null
    @sessionJar = null
    @gameKey = null
    @lobbyId = null
    @queuerId = null
    @startTime = 0
    @dispatcher = new Dispatcher();
    @log.info("Initializing game")
    @game = new Game(@dispatcher);
    @brain = new Brain(@game)
    @player = null
    @players = {}
    @socket = null
    @lobbySocket = null
    @internalState = null
    @bindDispatcher();

  init: (details) =>
    if details?
      if details.team? && !isNaN(details.team)
        @team = details.team
      if details.race?
        @race = details.race
      if details.fakePerson?
        @fakePerson = details.fakePerson
    attributes = if details? then details.attributes else null
    @brain.init(attributes)
    @log.info("Calling bot init with details: ", details)
    @id = rs.generate(32);
    @sessionId = rs.generate(32);
    @cookieJar = request.jar()
    @cookieJar.trackId = @trackId

  pickRace: (excludedRaces) =>
    log.info("#{@trackId} Calling pick Race with excludedRaces: ", excludedRaces)
    racesArray = _.difference(_.keys(races), excludedRaces)
    log.info("Races array: ", racesArray);
    totalRaces = racesArray.length
    return racesArray[Math.floor(Math.random()*totalRaces)];
    
  pickMinions: () =>
    availableMinions = _.keys(minions)
    selectedMinions = []
    while selectedMinions.length < config.maxMinions
      randomNum = Math.floor(Math.random() * availableMinions.length)
      selectedMinions.push(availableMinions.splice(randomNum, 1)[0])
    return selectedMinions
    

  authenticate: (callback) =>
    cookieJars[@id] = @cookieJar
    overrideXmlHttpRequest()
    @log.info("[#{@trackId}] Authenticating to lobby: " + netconfig.lobby.url)
    request {url: netconfig.lobby.url + "/auth/temp?username=bot&password=bot", jar: @cookieJar, timeout: botConfig.requestTimeout}, (err, res, body) =>
      if err
        @log.error("[#{@trackId}] Authentication error: ", err)
        return callback(err)
      @log.info("Successfully setup user account")
      callback(null, true)


  createGame: (server, callback) =>
    serverUrl = @getServerUrl(server, 'create')
    @log.info("Creating game serverUrl: " + serverUrl)
    request {url: serverUrl, jar: @cookieJar, timeout: botConfig.requestTimeout}, (err, res, body) =>
      if err
        @log.error("[#{@trackId}] create game returned error: ", err)
        return callback(err)
      @log.info("Created game")
      cookie = @cookieJar.cookies[0].str
      @sessionId = @getSessionId(cookie);
      header = res.req._header;
      keyMatch = header.match(/GET \/game\/(.*) /);
      gameKey = keyMatch[1]
      if gameKey?
        @authenticate (err, res) =>
          @joinGame server, gameKey, (err, res) =>
            return callback(err, res)
      else
        return callback {error: "Failed to get game Key"}, null

  joinGame: (server, key, callback) =>
    serverUrl = @getServerUrl(server, key)
    @log.info("Connecting to url: " + serverUrl)
    @socket = io.connect(serverUrl, {multiplex: false, reconnect: false, 'force new connection': true});
    @socket.on 'error', (err) ->
      log.error("Websocket failed to connect to server: " + serverUrl + " err is: " + err)
      return callback(err)
    @bindSockets (err, playerDetails) =>
      if err
        @log.error("[#{@trackId}] received error binding sockets: ", err)
        return callback(err)
      @log.info(@trackId + " bound socket and received playerDetails of: ", playerDetails);
      @bindSocketForGameDetails();
      callback(null, playerDetails)

  getServerUrl: (server, key) =>
    if server.indexOf ':' == -1
      server += ":" + netconfig.gs.port
    serverUrl = 'http://' + server + '/game/' + key + '?botId=' + @id
    return serverUrl

  getLobbySocketUrl: (callback) =>
    request {url: netconfig.lobby.url + '/', jar: @cookieJar, timeout: botConfig.requestTimeout}, (err, res, body) =>
      if err then return callback(err)
      if !body then return callback(new Error("No bodyData receieved from lobby"))
      try
        bodyData = JSON.parse(body)
      catch e
        @log.error("Failed to parse lobby body: ", body)
        return callback(e)
      host = bodyData.server
      serverUrl = 'http://' + host + ':' + netconfig.lobby.port + '/sockets/lobby/?botId=' + @id
      @log.info("Got lobby serverUrl: " + serverUrl)
      callback(null, serverUrl)

  getSessionId: (cookie) =>
    if !cookie?
      return null;
    key = "sessionId"
    decode = decodeURIComponent
    return (if (result = new RegExp("(?:^|; )" + encodeURIComponent(key) + "=([^;]*)").exec(cookie)) then decode(result[1]) else null)

  afterLobbyAuth: () =>
    if !@fakePerson
      configObject = {team: @team, isBot: true}
    else
      configObject = {}
      if @race?
        configObject['race'] = @race
        configObject['ready'] = true
    @log.info("configuring with config object: ", configObject)
    @emit(netMsg.player.configure, configObject)

  getRacesOnTeam: (players, team) ->
    racesOnTeam = _.values(players)
    .filter((player) -> player.team == team)
    .reduce((races, player) ->
      races.push(player.race);
      return races;
    , [])
    racesOnTeam = _.uniq(racesOnTeam, true)

  changeRace: (race, callback) ->
    @log.info("User " + @userId + " Changing race to " + race)
    @emit netMsg.player.configure, {race}, (err, result) =>
      if !err
        @race = race
      return callback(err, result)
    
  findAndPickRace: (callback) ->
    excludedRaces = @getRacesOnTeam(@players, @team);
    race = @pickRace(excludedRaces)
    @log.info("Changing race")
    @changeRace race, (err, result) =>
      @log.info("Back from change race")
      if err
        @log.info("Recieved error picking race. message is: " + err.message);
        return @findAndPickRace(callback);
      return callback(null, race);
    
  changeMinions: (chosenMinions, callback) ->
    @log.info("User " + @userId + " Changing minions to " + chosenMinions)
    @emit netMsg.player.configure, {minions: chosenMinions}, (err, result) =>
      if !err
        @minions = chosenMinions
      return callback(err, result)
    
  findAndPickMinions: (callback) ->
    chosenMinions = @pickMinions()
    @changeMinions chosenMinions, (err, result) =>
      if err
        @log.info("Recieved error picking minions. message is: " + err.message);
        return @findAndPickMinions(callback);
      return callback(null, chosenMinions);

  reportReady: () ->
    @log.info("User " + @userId + " Reporting ready")
    @emit netMsg.player.configure, {ready: true}, (err, result) =>
      @ready = true

  changeName: (name, callback) ->
    @name = name
    @log.info("Calling change name with name #{name}")
    request {url: netconfig.lobby.url + "/user/update/username/#{@name}", jar: @cookieJar, timeout: botConfig.requestTimeout}, (err, res, body) =>
      @log.info("Change name request return is: err: ", err, " body: ", body)
      if err then return callback(err)
      if !@socket #We're not connected to a game yet
        callback(null, true)
      else
        @emit netMsg.player.refresh, (success) =>
          @log.info("#{@trackId} Successfully refreshed bot")
          callback(null, success)

  receivedGameDetails: (details) =>
    if @gameState == config.states.finished
      return false;
    if !@game
      @log.error("Somehow game is null in receivedGameDetails")
      return false
    @game.init(details.code)
    @players = details.players
    @configurePlayer details, (err) =>
      @reportReady()
    
  configurePlayer: (details, callback) =>
    done = (err) =>
      @ready = true
      @configuringPlayer = false
      callback(err)
      
    if details.state == config.states.selection && !@ready && !@configuringPlayer
      @configuringPlayer = true
      @findAndPickRace (err, race) =>
        if (err) then return done(err)
        @log.info("Picked race " + race)
        @changeName f.ucFirst(race) + "Bot", (err, res) =>
          if (err) then return done(err)
          @findAndPickMinions (err, minions) =>
            if (err) then return done(err)
            @log.info("Picked minions ", minions)
            @configuringPlayer = false
            done()
        
  bindSockets: (callback) =>
    @socket.on 'connect', () =>
      @log.info("#{@trackId} connected!");
    @socket.on netMsg.player.details, (details) =>
      if !@game
        return @log.error("Got player details when @game is null", {details: details, gameState: @gameState})
      @game.setPlayerDetails(details)
      callback(null, details)
      @gameState = config.states.lobby
      @afterLobbyAuth();
    @socket.on netMsg.disconnect, =>
      @disconnected();
      
  bindSocketForGameDetails: (callback) =>
    @socket.on netMsg.game.details, (details) =>
      @receivedGameDetails(details)
    @socket.on netMsg.game.start, (data) =>
      @gameStarted()
    @socket.on netMsg.game.begin, (details) =>
      @beginGame details
    @socket.on netMsg.game.end, (winningTeam) =>
      @end winningTeam
    @socket.on netMsg.game.tickData, (tick, data, callback) =>
      @processTickData tick, data
      if callback?
        callback();

  bindDispatcher: () =>
    @dispatcher.on botConfig.messages.collectGem, (gemId) =>
      @collectGem(gemId)

  disconnected: () =>
    @log.info "Bot disconnected for some reason :("
    @end();

  end: (winningTeam) =>
    if @gameState == config.states.finished
      return false;
    @log.info("Bot dying caus the game ended. Winning team is " + winningTeam)
    @gameState = config.states.finished
    if @socket?
      @log.info("Disconnecting socket")
      @socket.disconnect();
    else
      @log.error("In end but socket is null so can't disconnect")
    if @lobbySocket?
      @log.info("Disconnecting lobby socket")
      @lobbySocket.disconnect()
    else
      @log.error("In end but lobbySocket is null so can't disconnect")
    @log.info("Ending game")
    if @game
      @game.end();
    delete cookieJars[@id]
    @log.info("Deleting game")
    delete @game
    delete @brain
    delete @socket
    delete @lobbySocket
    return true;

  gameStarted: () =>
    @log.info "Game started"
    @gameState = config.states.started
    reportLoadedDelay = if @fakePerson then Math.round(Math.random()*botConfig.reportLoadedMaxDelay) + botConfig.reportLoadedMinDelay else 2000
    setTimeout((=> @reportLoaded()), reportLoadedDelay);

  reportLoaded: =>
    @log.info "Reporting loaded"
    @emit netMsg.player.loaded

  beginGame: (details) =>
    @log.info "Game beginning with details: ", details
    playerId = details.playerId
    players = details.players
    @startTime = new Date().getTime();
    if !@game
      return @log.error("Did beginGame when @game is null", {details: details, gameState: @gameState})
    @players = players
    if _.find(@players, {id: playerId})?
      @player = _.find(@players, {id: playerId})
      @game.setPlayerDetails(@player)
    @dispatcher.emit botConfig.messages.gameBeginning, details
    setTimeout((=> @update()), 50);

  getCurrentTick: () =>
    return @game.getCurrentTick();

  processTickData: (tick, data) =>
    if @game?
      @game.processTickData tick, data

  placeTower: (x, y, towerType) =>
    @emit netMsg.game.placeTower, x, y, towerType

  upgradeTower: (settings) =>
    if settings
      @emit netMsg.game.upgradeTower, settings

  placeMinion: (xCoord, yCoord, type) =>
    if type
      @emit netMsg.game.placeMinion, xCoord, yCoord, type

  collectGem: (id) =>
    @emit netMsg.game.collectGem, id

  update: () =>
    if @gameState == config.states.finished
      return false;
    currentTick = @getCurrentTick();
    if currentTick != @lastTick
      turn = @brain.getNextTurn()
      if turn.action == botConfig.actions.placeMinion && turn.settings?
        @placeMinion(turn.settings.x, turn.settings.y, turn.settings.type)
      if turn.action == botConfig.actions.buildTower && turn.settings?
        @placeTower(turn.settings.x, turn.settings.y, turn.settings.type)
      if turn.action == botConfig.actions.upgradeTower
        @upgradeTower(turn.settings)
      @lastTick = currentTick
    setTimeout((=> @update()), 50)

  emit: () =>
    if !@socket then return false
    args = Array.prototype.slice.call(arguments, 0)
    try
      @socket.emit.apply(@socket, args)
    catch e
      @log.error("socket emit returned error: ", e)
      @socket = null
    return true













module.exports = Bot

