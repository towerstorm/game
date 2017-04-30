Player = require './../lib/player'
tdb = require('database')
rs = require 'randomstring'
bulkLoad = require("config/bulk-load");
races = bulkLoad("races");
request = require('request')
netMsg = require 'config/net-messages'
gameMsg = require 'config/game-messages'
config = require 'config/general'
serverConfig = require 'config/gameserver'
events = require 'events'
http = require 'http'
cookie = require 'cookie'
cookieParser = require 'cookie-parser'
connect = require 'connect'
netconfig = require 'config/netconfig'
bots = require './../lib/bots'
async = require 'async'
log = require('../../logger')
_ = require 'lodash'
metrics = require('../lib/metrics')
io = require("../lib/socket-io").io
sessionStore = tdb.sessionStore
uuid = require 'node-uuid'
User = tdb.models.User
Queuer = tdb.models.Queuer
Model = tdb.models.Model
util = require 'util'


delay = (ms, func) -> setTimeout func, ms
noop = -> true

class Game extends Model
  tableName: 'games'
  data: null
  state: config.states.none
  initTime: null
  code: null
  socket: null
  name: null
  minionManager: null
  lastUpdate: 0
  hostId: null
  chatRoomIds: {}
  players: []
  playerTeamAllocations: null   #Used for matchmaking to preallocate players to teams so they're with their friends
  totalPlayers: 0
  maxPlayers: 6
  state: null
  log: null
  gameLog: null
  deleteSelf: null
  lastProcessTickTime: 0
  
  gameSnapshot: {}
  gameSnapshotHash: {}   #For each 100 ticks it stores a hash of the game state and compares it to clients.

  startDelay: 10

  settings: {}
  gameEndCheck: null
  finishedReports: []

  constructor: (data) ->
    @data = data || {}
    _.extend(@data, {
      lastTick: null,
      winningTeam: null,
      errors: []
    });
    @setState(config.states.none)
    metrics.activeGames.inc(1)
    log.increment('gameserver.activeGames');
    metrics.lastGameStart = Date.now();

  init: (callback = noop) ->
    @setState(config.states.init)
    @initTime = Date.now()
    @set('code', rs.generate(6))
    @set('created', Date.now())
    @set('ticks', {})
    @log = new (log.Logger)({
      transports: log.getCustomTransports('gameserver', [@get('code')])
    })
    @log.info("Constructing game, state is ", @get('state'))
    if serverConfig.enableDebugLog && process.env.NODE_ENV == "development"
      transports = [new (log.transports.File)({ filename: serverConfig.logDir + '/game-logs-server/' + @get('code') + '.log', timestamp: false})]
      @gameLog = new (log.Logger)({
        transports: transports
      })
    @socket = null
    @lastUpdate = new Date().getTime();
    @chatRoomIds = {
      all: uuid.v4()
      team0: uuid.v4()
      team1: uuid.v4()
    }
    @bindSockets();
    @bindDispatcher();
    @players = []
    @playerTeamAllocations = null
    @totalPlayers = 0
    @gameSnapshot = {}
    @gameSnapshotHash = {}
    @finishedReports = []
    @set('settings', {
      mapId: "deep-space-collision"
      mode: "PVP"
      difficulty: 0
      targetTime: 600
      incomeMultiplier: 0.5
      linearGold: false
      castleBonuses: false
    })

    @allocatePlayerTeams (err, success) =>
      if err
        log.warn("Failed to allocate teams, error is: " + err.message)
        return callback(err)
      if @isCustomGame()
        setTimeout((=> @checkSomeoneConnected()), serverConfig.waitForHostToConnectTime * 1000);
      else
        setTimeout((=> @checkEveryoneConnected()), serverConfig.waitForAllToConnectTime * 1000);
        setTimeout((=> @start()), serverConfig.timeBeforeStart * 1000)
      @log.info("Game #{@id} init complete")
      @setState(config.states.lobby)
      @save (err, self) ->
        callback(null, true)

  save: (callback) =>
    @set('players', @getPlayers())
    @set('lastUpdate', Date.now())
    super(callback)

  # We do dispatcher stuff so that the lobby can be notified when
  # Game details change and it can update all current watchers.
  bindDispatcher: =>
    @dispatcher = new events.EventEmitter;

  bindSockets: =>
    @log.info("Creating game with code: " + @get('code'), {matchId: @matchId})
    io.set 'authorization', (handshakeData, accept) =>
      @log.verbose("Handshake headers: ", handshakeData.headers)
      if handshakeData.headers.cookie
        handshakeData.cookie = cookie.parse(handshakeData.headers.cookie);
        handshakeData.sessionId = cookieParser.signedCookie(handshakeData.cookie[serverConfig.cookieKey], serverConfig.cookieSecret);
        if handshakeData.cookie[serverConfig.cookieKey] == handshakeData.sessionId
          return accept('Cookie is invalid.', false);
      else
        return accept('No cookie transmitted.', false);
      accept(null, true)
    @socket = io.of('/game/'+@get('code')).on "connection", (socket)=>
      sessionId = socket.handshake.sessionId
      @log.info("Got new connection to game, sessionId is: ", sessionId)
      if sessionId
        sessionStore.get sessionId, (err, session) =>
          @log.info("Got sessionId: ", sessionId, " user: ", session.passport.user)
          if !err
            userId = session.passport.user
            User.findById userId, (err, user) =>
              if !err
                @userConnected(user.get('id'), user.get('username'), socket)

  autoAddBots: (callback) =>
    if !serverConfig.autoAddBots || @get('settings').mode == "TUTORIAL" || !@isCustomGame() || @get('settings').mode == "SANDBOX"
      return false

    async.each([1, 2, 3, 4, 5], ((item, callback) => setTimeout((=> @addBot({team: ((item % 2) + 1)}, callback)))), callback)


  userConnected: (userId, username, socket) =>
    if @players.length == 0
      @autoAddBots()
    player = @getPlayer(userId)
    if !player?
      player = new Player(log)
      player.init userId
      player.name = username
    @playerJoin(player, socket)

  ###
    When in matchmaking mode start the game if all users are ready
  ###
  userReady: =>
    @log.info("User is ready")
    if @checkPlayersAreReady()
      @start()

  checkPlayersAreReady: =>
    metaData = {matchId: @matchId}
    @log.info("Checking if players are ready", metaData)
    totalPlayersReady = 0
    for player in @players
      if !player.ready
        return false
      else
         totalPlayersReady++
    @log.info("#{totalPlayersReady} players are ready, totalPlayers is: #{@totalPlayers}", metaData)
    if totalPlayersReady < @totalPlayers
      return false
    return true

  checkPlayersAreLoaded: =>
    @log.info("Doing check players are loaded. State is: " + @get("state"))
    if @get('state') != config.states.started
      return false
    totalPlayersLoaded = 0
    for player in @players
      @log.info("Player ", player.name, ' is ', player.isLoaded() ? "loaded" : "not loaded")
      if !player.isLoaded()
        return false
      else
        totalPlayersLoaded++
    @log.info("Checking players are loaded, totalPlayersLoaded: ", totalPlayersLoaded, " Total Players: ", @totalPlayers)
    if totalPlayersLoaded < @totalPlayers
      return false;
    @log.info("Beginning game")
    setTimeout (=> @begin()), 2000

  getTotalConnectedPlayers: =>
    return @getPlayers().length

  ###
   * This is called just after the game is started
   * to ensure that someone actually connected to the game
   * and if no one did it ends the game, so that if a host starts
   * but never connects via a websocket the game doesn't run forever
  ###
  checkSomeoneConnected: =>
    @log.info("In checkSomeoneConnected, totalPlayer is: " + @totalPlayers)
    if @totalPlayers <= 0
      @log.warn("Ending game because someone started it but never joined it")
      @end();

  ###
   * This is called just after a matchmaking game is started
   * to ensure that everyone connected successfully
   * because an unbalanced game is not fun
  ###
  checkEveryoneConnected: =>
    totalConnectedPlayers = @getTotalConnectedPlayers()
    @log.info("In checkEveryoneConnected, totalPlayer is: " + totalConnectedPlayers, {matchId: @matchId})
    if totalConnectedPlayers < 6
      if totalConnectedPlayers == 0 then errorLevel = 'warn' else errorLevel = 'error'
      @log[errorLevel]("Ending ranked game due to not all players connecting", {totalPlayers: totalConnectedPlayers, matchId: @matchId})
      @cancel();

  ###
   * This is when the host has clicked the start button in the lobby 
   *
  ###
  startSelection: =>
    @log.info("Game going into selection mode")
    @setState(config.states.selection)
    @broadcastDetails()
    
  start: =>
    @log.info("Game starting state is: " + @get('state'))
    if @get('state') != config.states.selection
      return false
    @allocateRandomRaces()
    @setState(config.states.started)
    @socket.emit(netMsg.game.start)

  ###
   * When all players are loaded and the game is actually beginning
   *
  ###
  begin: =>
    playerData = @getPlayers();
    @log.info("All players have loaded, Doing begin game players is", playerData)
    for team in [0..1]
      totalOnTeam = playerData.map((p) -> p.team).filter((t) -> t == team).length
      if totalOnTeam != 3
        @log.error("There are " + totalOnTeam + " players on team " + team + " when there should be 3")
    @gameSnapshot = {}
    @gameSnapshotHash = {}
    if @get('settings').mode == "TUTORIAL"
      @get('settings').mapId = "tutorial-1"
    if @get('settings').mode == "SANDBOX"
      @get('settings').mapId = "sandbox-1"
    @log.info("Beginning game mode: " + @get('settings').mode + " mapId: " + @get('settings').mapId)
    gameSettings = {settings: @get('settings'), players: @getPlayers()}
    @set('startTime', Date.now());
    @processPlayerActions();
    @setState(config.states.begun)
    for player in @players
      gameSettings.playerId = player.id
      player.socket.emit(netMsg.game.begin, gameSettings)
    setTimeout((=> @end()), serverConfig.maxGameTimeInMinutes * 60 * 1000); # Games must end after two hours no matter what happens
    return true;

  cancel: =>
    @log.info("Called cancel", {matchId: @matchId})
    @socket.emit(netMsg.game.didNotConnect)
    @end();

  end: (winningTeam) =>
    if @get('state') == config.states.finished
      return false
    @log.info("Ending game")
    @set('winningTeam', winningTeam)
    @setState(config.states.finished)
    @socket.emit(netMsg.game.end, winningTeam)
    @updatePlayerProfilesAtEnd winningTeam, (err, didUpdate) =>
      for player in @players
        player.disconnect()
      delete @players
      delete @socket
    metrics.activeGames.dec(1)
    log.decrement('gameserver.activeGames');

  configure: (details, callback) =>
    @log.info "In game update details are: ", details
    if !details?
      return callback(false)
    settings = @get('settings')
    for name, value of details
      if settings[name]?
        settings[name] = value
    @set('settings', settings)
    @broadcastDetails()
    callback(true)

  # Called when a player says the game has finished, checks if the other players agree
  playerFinished: (playerId, winningTeam, lastTick) =>
    player = @getPlayer(playerId);
    @finishedReports.push({playerId, winningTeam, lastTick});
    if @finishedReports.length == @getTotalHumans()
      return @checkFinishedReports();
    setTimeout((=> @checkFinishedReports()), 10 * 1000); #Even if we don't have enough reports check with what we have
    
  getTotalHumans: =>
    totalHumans = @totalPlayers
    for player in @players
      if player.isBot
        totalHumans--
    return totalHumans
      
  # Checks the player finished checkins to see what the outcome is
  checkFinishedReports: () =>
    @log.info("Checking finished reports. Total: " + @finishedReports.length + " Total humans: " + @getTotalHumans())
    winningTeam = null
    lastTick = null
    for finishedReports in @finishedReports
      if winningTeam? && winningTeam != @finishedReports.winningTeam
        return @reportError(new Error("Inconsistent winningTeam received from players"));
      if lastTick? && lastTick != @finishedReports.lastTick
        return @reportError(new Error("Inconsistent lastTick recieved from players"));
      winningTeam = @finishedReports.winningTeam
      lastTick = @finishedReports.lastTick
    @set('lastTick', lastTick);
    @end(winningTeam)
      
  reportError: (err) =>
    @data.errors.push(err && err.message);
    @save();
    
  broadcastDetails: =>
    if @get('state') == config.states.finished
      return false
    data = @getDetails()
    @socket.emit netMsg.game.details, data
    
  calculateCurrentTick: () ->
    return Math.floor((Date.now() - @get('startTime')) / serverConfig.tickTime);
    
  processPlayerActions: () ->
    actionsDone = {}
    tick = @calculateCurrentTick()
    if tick > 2 && !@data.ticks[tick-1]?
      @log.error("Server missed tick: " + tick);
      # Recover by processing the missed tick now, and next processPlayerActions will handle the next one
      tick--;
    if @data.ticks[tick]?
      return setTimeout((=> @processPlayerActions()));
    for player in @players
      if player.lastAction? && player.lastAction.type
        lastAction = _.clone(player.lastAction)
        actionsDone[lastAction.type] = actionsDone[lastAction.type] || [];
        actionsDone[lastAction.type].push(lastAction.data)
      player.lastAction = null
    @processTick(tick, actionsDone)
    setTimeout((=> @processPlayerActions()));

  processTick: (tick, actionsDone) =>
    if @get('state') == config.states.lobby
      return false;
    if !actionsDone?
      actionsDone = {}
    else
      @data.ticks[tick] = _.clone(actionsDone)
      if !_.isEqual(actionsDone, {})
        @log.info("Tick Complete", {tick, actions: actionsDone})
    for player in @players
      # if !player.isBot
        # @log.info("Sending tick ", tick, " to player ", player.id)
      player.sendTick tick, actionsDone
    @set('currentTick', tick);
    
  resendTick: (tick, player) =>
    tickData = @data.ticks[tick]
    # @log.info("Resending tick ", tick, " with data ", tickData, " to player", player.id)
    if !tickData 
      tickData = {}
    player.sendTick tick, tickData

  ###
    Sets the in memory snapshot for this tick and also saves out the latest snapshot to the
    database for bots to read in and restoring games if the server dies.
  ###
  reportGameSnapshot: (tick, snapshot, snapshotHash) =>
    @gameSnapshot[tick] = snapshot
    @gameSnapshotHash[tick] = snapshotHash
    @set('snapshot', {tick, hash: snapshotHash, data: JSON.stringify(snapshot)})
    @save (err, self) =>
      if err
        @log.error("Got error when saving: ", err)

  setState: (state) =>
    @set('state', state)
    @save()

  setMode: (mode) =>
    if mode not in ["PVP", "TUTORIAL", "SURVIVAL", "SANDBOX"]
      return false
    settings = @get('settings')
    settings.mode = mode
    @set('settings', settings)
    @save()

  getMode: =>
    return @get('settings').mode

  ###
    Logs out the invalid game state to the controller
  ###
  reportInvalidState: (tick) =>
    require('../lib/desync').log @get('code'), tick, "server", @gameSnapshot[tick], (err, data) =>
      @log.info("Saved invalid state, it returned err: ", err, " data ", data)

  getPlayerTeam: (playerId) =>
    if @playerTeamAllocations && @playerTeamAllocations[playerId]?
      @log.info("Player " + playerId + " is allocated to team: " + @playerTeamAllocations[playerId])
      return @playerTeamAllocations[playerId]
    teamTotal = [0, 0, 0]
    for player in @players
      teamTotal[player.team]++
    team = if teamTotal[1] > teamTotal[2] then 2 else 1
    @log.info("Allocating player " + playerId + " to team " + team)
    return team

  findFirstBot: =>
    for player in @players
      if player.isBot then return player
    return null

  playerJoin: (player, socket) =>
    @log.info("Player #{player.id} joining ")
    if !@getPlayer(player.id)?
      playerTeam = null
      if @isCustomGame()
        if @totalPlayers >= @maxPlayers && @get('state') == config.states.lobby
          firstBot = @findFirstBot()
          if firstBot
            @kickPlayer(@hostId, firstBot.id)
          else
            log.error("Kicking player from game due to the game being full")
            return socket.emit(netMsg.game.error, {error: netMsg.game.full})
      else
        if !_.has(@playerTeamAllocations, player.id)
          log.error("Kicking player due to not being in playerTeamAllocations list")
          return socket.emit(netMsg.game.error, {error: netMsg.game.private})
      player.setTeam(playerTeam || @getPlayerTeam(player.id))
      @addPlayer(player)
      @log.info("New player id #{player.id} connected")
    player.setSocket(socket)
    player.joinGame(@)
    player.sendDetails()
    if @get('state') == config.states.begun
      player.syncData();
    @broadcastDetails();

  playerUpdated: (playerId, changes) =>
    # if players team changed re-sort the players list putting the player at the bottom
    if changes.team?
      playerIndex = null
      for player, idx in @players
        if player.id == playerId
          playerIndex = idx
          break;
      updatedPlayer = @players.splice(idx, 1)
      @players = @players.concat(updatedPlayer);

  addPlayer: (player) =>
    if @get('state') == config.states.lobby && @isCustomGame()
      @totalPlayers++;
    @players.push player
    @broadcastDetails()
    if @gameEndCheck?
      clearTimeout(@gameEndCheck)
      @gameEndCheck = null
    return true

  kickPlayer: (requestingPlayerId, playerId) =>
    @log.info("Kicking player")
    if @get('state') != config.states.lobby
      return false;
    if requestingPlayerId != @hostId
      return false
    player = @getPlayer(playerId)
    if !player
      return false
    player.kick();
    @deletePlayer(player)

  ###
    Completely deletes a player and all settings for the game, done in the lobby state
    when players are constantly joining and leaving. Should not be done after the game has started
    so players can disconnect / reconnect if there is lag.
  ###
  deletePlayer: (findPlayer) =>
    success = false
    if @get('state') == config.states.finished
      return false
    for own id, player of @players
      if findPlayer == player
        @log.info "Found player and deleting"
        #Decrement the total players if we're still in lobby and one leaves. If the game has started we don't decrement so we can check all players are loaded and responding.
        if @get('state') == config.states.lobby && @isCustomGame()
          @totalPlayers--;
        @players.splice id, 1
        findPlayer.disconnect(); #This triggers disconnect which calls deletePlayer again but 2nd time through it will have been spliced out so deletePlayer is called twice but just fails the 2nd time
        @broadcastDetails()
        success = true
    if @get('state') == config.states.lobby && @totalPlayers <= 0
      @log.warn("Deleted player from game and totalPlayers is 0 so ending game")
      @end();
    return success

  playerConnected: (player) =>
    if @gameEndCheck?
      clearTimeout(@gameEndCheck)
      @gameEndCheck = null

  playerDisconnected: (player) =>
    playersConnected = 0
    for own id, player of @players
      if player.disconnected == false && !player.isBot
        playersConnected++
    if playersConnected == 0 && @get('state') in [config.states.started, config.states.begun] && !@gameEndCheck?
      @gameEndCheck = setTimeout((=> @checkIfGameShouldEnd()), serverConfig.disconnectedSecondsBeforeGameEnds * 1000);

  addBot: (details, callback = noop) =>
    @log.info("GameServer requesting bot", {details})
    if @get('state') != config.states.lobby
      return callback("Game is not in lobby")
    bots.add(@get('code'), details, callback)

  configureBot: (requesterUserId, details) =>
    if requesterUserId != @hostId
      return false
    bot = @getPlayer(details.playerId)
    bots.configure(bot, details)

  getDetails: () =>
    players = @getPlayers()
    details =
      name: @name
      code: @get('code')
      state: @get('state')
      players: players
      hostId: @hostId
      chatRoomIds: @chatRoomIds
      settings: @get('settings')
    if !@isCustomGame() && @get('state') == config.states.lobby
      details.timeRemaining = Math.floor((@initTime + (serverConfig.timeBeforeStart * 1000) - Date.now()) / 1000)
    return details

  getTicks: () =>
    return @get('ticks')

  getCurrentTick: () =>
    return @get('currentTick');

  getPlayer: (id) =>
    for player in @players
      if player.id == id
        return player
    null

  getPlayers: () =>
    playersList = []
    for i in @players
      playersList.push
        id: i.id
        name: i.name
        race: i.race
        minions: i.minions
        team: i.team
        isBot: i.isBot
        ready: i.ready
        loaded: i.loaded
    return playersList

  isCustomGame: =>
    return @hostId != null

  isRaceSelected: (race, team) =>
    for player in @players
      if player.race == race && player.team == team
        return true
    return false

  ###
    Called in a callback when all players are disconnected, if they are still
    disconnected after disconnectedSecondsBeforeGameEnds the game will end
  ###
  checkIfGameShouldEnd: =>
    @gameEndCheck = null
    for player in @players
      if player.disconnected == false && !player.isBot
        return false;
    @log.warn("Ending game due to all players being disconnected")
    @end();

  updatePlayerProfilesAtEnd: (winningTeam, callback) =>
    if @isCustomGame() then return callback(null, false)
    if !winningTeam? then return callback(null, false)
    asyncTasks = []
    @calculateEloChange winningTeam, (err, eloChange) =>
      if err
        log.warn("calculateEloChange returned error: " + err.message)
        eloChange = 8
      @players.forEach (player) =>
        asyncTasks.push (done) =>
          User.findById player.id, (err, user) =>
            if err then return done()
            experience = user.get('experience')
            stormPoints = user.get('stormPoints')
            user.set('experience', experience + serverConfig.experiencePerGame)
            user.set('stormPoints', stormPoints + serverConfig.stormPointsPerGame)
            if player.team == winningTeam
              user.set('wins', user.get('wins') + 1)
              user.set('elo', user.get('elo') + eloChange)
            else
              user.set('losses', user.get('losses') + 1)
              user.set('elo', user.get('elo') - eloChange)
            user.save(done)
      async.parallel asyncTasks, (err, users) =>
        if err then return callback(err)
        @log.info("Done updating player profiles. users after update are: ", _.map(users, (user) -> if !user then {} else user.data))
        return callback(null, true)

  calculateEloChange: (winningTeam, callback) =>
    @getTeamElos (err, teamElos) =>
      @log.info("Team elos are: ", teamElos)
      chanceForTeamZeroToWin = 1 / ( 1 + Math.pow(10, ((teamElos[1] - teamElos[0]) / 400 )))
      @log.info("Chance to win: ", chanceForTeamZeroToWin)
      if winningTeam == 0
        eloMultiplier = 1 - chanceForTeamZeroToWin
      else
        eloMultiplier = chanceForTeamZeroToWin
      eloChange = Math.round( serverConfig.eloWeightingFactor * eloMultiplier)
      @log.info("Elo change is: ", eloChange)
      callback(null, eloChange)

  getTeamElos: (callback) =>
    asyncTasks = []
    teamElos = [0, 0]
    @players.forEach (player) =>
      asyncTasks.push (done) =>
        User.findById player.id, (err, user) =>
          if err then return done()
          @log.info("Adding player " + player.id + " elo of " + user.get('elo') + " to team " + player.team)
          teamElos[player.team] += user.get('elo')
          done(null, user)
    async.parallel asyncTasks, (err, users) =>
      teamAverageElos = teamElos.map((tae) -> tae / 3)
      callback(null, teamAverageElos)

  ###
    Only used for matchmaking, figures out what players go on what teams
    based on their queuer groups. So people that queued together always go on the same team
    Creates object of <id>: <team>
  ###
  allocatePlayerTeams: (callback = noop) =>
    if !@matchId then return callback()
    @log.info("Allocating players to teams. Setting total players to 6")
    if @playerTeamAllocations
      @log.info("Player team allocations is already set, returning")
      return callback()
    @totalPlayers = 6
    @playerTeamAllocations = {}
    Queuer.findAllByMatchId @matchId, (err, queuers) =>
      if err
        log.error("Queuer.findAllByMatchId failed, err: " + err.message + " stack: " + err.stack)
        return callback(err)
      teamTotals = [0, 0]
      queuers.forEach (queuer) =>
        userIds = queuer.get('userIds')
        for t in [0..1]
          if teamTotals[t] < 3 && teamTotals[t] + userIds.length <= 3
            team = t
            break
        for userId in userIds
          @playerTeamAllocations[userId] = team
        teamTotals[team] += userIds.length
      @log.info("Allocations complete, they are: ", {allocations: @playerTeamAllocations})
      callback(null, true)

  ###
    For matchmaking, goes through all players who have not chosen a race
    and allocates them a random race.
  ###
  allocateRandomRaces: () =>
    if @isCustomGame()
      return false
    @log.info("Doing allocateRandomRaces")
    raceNames = _.keys(races)
    for player in @players
      while player.race == null
        @log.info("Player #{player.id} has not chosen a race")
        race = raceNames[Math.floor(Math.random()*raceNames.length)]
        if !@isRaceSelected(race, player.team)
          @log.info("Choosing race #{race} for player")
          player.setRace(race)

Game.getNextId = (callback) ->
  _.defer ->
    id = uuid.v4()
    callback(null, id)

Game.create = (callback) ->
  Game.getNextId (err, id) ->
    log.info("Called game model create")
    game = new Game({
      id: id
    })
    return callback(null, game)

module.exports = Game;