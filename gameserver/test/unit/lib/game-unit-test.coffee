assert = require 'assert'
sinon = require 'sinon'
proxyquire = require 'proxyquire'
Player = require '../../../lib/player'
config = require 'config/general'
serverConfig = require 'config/gameserver'
Dispatcher = require '../dispatcher-mock'
GameModel = require '../mocks/game-model-mock'
gameMsg = require 'config/game-messages'
netMsg = require 'config/net-messages'

UserMock = {
  findById: -> {}
}
QueuerMock = {
  findAllByMatchId: -> []
}
noop = ->
class ModelMock
  data: {}
  set: (item, value) -> @data[item] = value
  get: (item) -> @data[item]
  save: (callback = noop) -> callback()
dbMock = {
  models: {
    User: UserMock
    Queuer: QueuerMock
    Model: ModelMock
  }
}

Game = proxyquire '../../../models/game', {
  'game': IGMock
  'game/lib/game/main': IGGameMock
  'database': dbMock
}
Game.register = ->
Game.updateState = ->
Game.postToLobby = ->
game = null

describe "Server Game", ->
  beforeEach ->
    app =
      settings:
        socketIO: null
    game = new Game(app)
    game.log = {
      debug: ->
      info: ->
      warn: ->
      erro: ->
    }
    game.data.startTime = 0
    game.data.ticks = {};
    game.socket = {
      emit: ->
    }

  describe "init", ->
    beforeEach ->
      game.bindSockets = -> assert true
      game.bindDispatcher = -> assert true
      game.bindIGDispatcher = -> assert true
      game.checkSomeoneConnected = -> assert true
      game.checkEveryoneConnected = -> assert true
      game.autoAddBots = -> assert true
      game.start = -> assert true

    it "should set the state to lobby", (done) ->
      game.init ->
        assert.equal(game.data.state, config.states.lobby)
        done()

    it "should set ticks to {}", (done) ->
      game.init ->
        assert.deepEqual(game.data.ticks, {})
        done()

    describe "call checkSomeoneConnected", ->
      calledCheckSomeoneConnected = false
      beforeEach (done) ->
        game.hostId = "123"
        serverConfig.waitForHostToConnectTime = 0.1;
        game.checkSomeoneConnected = ->
          calledCheckSomeoneConnected = true
          done();
        game.init()

      it "should call checkSomeoneConnected after waitForHostToConnectTime seconds", ->
        assert.equal calledCheckSomeoneConnected, true

  describe "bindSockets", ->

  describe "registerWithLobb" , ->

  describe "autoAddBots", ->
    it "Should call addBot twice with team 0 and three times with team 1", (done) ->
      serverConfig.autoAddBots = true
      game.hostId = '123'
      addBot = sinon.stub(game, 'addBot').callsArgWith(1, 0)
      game.autoAddBots (err, botNums) ->
        assert.deepEqual addBot.getCall(0).args[0], {team: 1}
        assert.deepEqual addBot.getCall(1).args[0], {team: 0}
        assert.deepEqual addBot.getCall(2).args[0], {team: 1}
        assert.deepEqual addBot.getCall(3).args[0], {team: 0}
        assert.deepEqual addBot.getCall(4).args[0], {team: 1}
        addBot.restore()
        done()

  describe "userConnected", ->

  describe "checkPlayersAreLoaded", ->

  describe "checkSomeoneConnected", ->
    beforeEach ->
      game.end = -> assert true

    it "Should end the game if total players is 0", ->
      game.totalPlayers = 0
      calledEnd = false
      game.end = ->
        calledEnd = true

      game.checkSomeoneConnected();
      assert.equal calledEnd, true

    it "Should not end the game if total players is greater than 0", ->
      game.totalPlayers = 1
      calledEnd = false
      game.end = ->
        calledEnd = true

      game.checkSomeoneConnected();
      assert.equal calledEnd, false

  describe "checkEveryoneConnected", ->
    beforeEach ->
      game.cancel = -> true
      game.log = {
        info: -> true
        warn: -> true
        error: -> true
      }

    it "Should emit a warning if totalConnectedPlayers is 0 because it could just be a game that all players didn't accept", ->
      game.getTotalConnectedPlayers = -> 0
      sinon.stub(game.log, 'warn')
      game.checkEveryoneConnected()
      assert game.log.warn.calledOnce

    it "Should emit an error if totalConnectedPlayers is > 0 && < 6 because something fucked up", ->
      game.getTotalConnectedPlayers = -> 3
      sinon.stub(game.log, 'error')
      game.checkEveryoneConnected()
      assert game.log.error.calledOnce




  describe "start", ->

  describe "begin", ->

  describe "cancel", ->
    beforeEach ->
      game.socket = {emit: ->}
      game.end = ->

    it "Should send game cancelled message to all players", () ->
      sinon.stub(game.socket, 'emit')
      game.cancel()
      assert game.socket.emit.calledWith(netMsg.game.didNotConnect)
      game.socket.emit.restore()

    it "Should call end", () ->
      sinon.stub(game, 'end')
      game.cancel()
      assert game.end.calledOnce
      game.end.restore()







  describe "end", ->
    beforeEach ->
      game.deleteSelf = -> assert true
      game.updatePlayerProfilesAtEnd = -> assert true

    it "should set game state to finished", ->
      game.data.state = config.states.begun;
      game.end();
      assert.equal game.data.state, config.states.finished

    it "should return false if the state is already finished", ->
      game.data.state = config.states.finished
      funcReturn = game.end();
      assert.equal funcReturn, false

  describe "broadcastDetails", ->
    it "Should return false if state is finished", ->
      game.data.state = config.states.finished
      returnCode = game.broadcastDetails();
      assert.equal returnCode, false
      
  describe "processPlayerActions", ->
    it "Should add all the actions players have done to one array", (done) ->
      game.players = [
        {lastAction: {type: "minions", data: {xPos: 1, yPos: 2, type: "goblin"}}},
        {lastAction: {type: "minions", data: {xPos: 9, yPos: 10, type: "ogre"}}},
        {lastAction: {type: "towers", data: {xPos: 3, yPos: 8, type: "crossbow"}}},
      ]
      sinon.stub(game, 'processTick');
      game.processPlayerActions(5);
      game.processTick.calledWith(5, {
        "minions": [
          data: {xPos: 1, yPos: 2, type: "goblin"}, 
          data: {xPos: 9, yPos: 10, type: "ogre"},
        ],
        "towers": [
          data: {xPos: 3, yPos: 8, type: "crossbow"}
        ]
      });
      game.processPlayerActions = ->
        done();
        
      

  describe "processTick", ->
    beforeEach ->
      global.metricsServer = {
        addMetric: -> true
      }

    it "Should send the tick to each player", ->

    it "Should not store the tick but should set currentTick if there is no data", ->
      game.set('ticks', {})
      tick = 4
      commandsDone = null
      gameStateHash = 23823212902;
      game.processTick tick, commandsDone, gameStateHash
      assert !game.get('ticks')[tick]?
      assert.equal game.get('currentTick'), 4

    it "Should store the tick in ticks if it has data", ->
      game.set('ticks', {})
      tick = 19
      commandsDone = "TestCommands"
      gameStateHash = 23823212902;
      game.processTick tick, commandsDone, gameStateHash
      assert game.get('ticks')[tick]?
      assert.equal game.get('ticks')[tick], commandsDone
      assert.equal game.get('currentTick'), 19
      
    it "Should create a copy of actionsDone instead of reference it directly", ->

  describe "reportGameSnapshot", ->
    it "Should set snapshot and snapshotHash and save them out to the db", ->
      sinon.stub(game, 'save')
      snapshot = {minions: {'one': 1}}
      snapshotHash = 'abc123'
      game.reportGameSnapshot(1, snapshot, snapshotHash)
      assert.deepEqual game.data.snapshot, {tick: 1, hash: snapshotHash, data: JSON.stringify(snapshot)}


  describe "setState", ->

  describe "setMode", ->

  describe "getMode", ->

  describe "reportInvalidState", ->

  describe "getPlayerTeam", ->
    it "Should return team 0 if there are no players in the match yet", ->
      game.players = []
      assert.equal game.getPlayerTeam(), 0

    it "Should allocate for team 0 when there are already many players on it if playerTeamAllocations says so", ->
      game.players = [{team: 0}]
      game.playerTeamAllocations = {'abc': 0, 'def': 0, 'gyy': 0}
      assert.equal game.getPlayerTeam('abc'), 0
      assert.equal game.getPlayerTeam('def'), 0
      assert.equal game.getPlayerTeam('gyy'), 0

    it "Should return playerTeamAllocation if it's set for this player", ->
      game.playerTeamAllocations = {'abc': 1}
      assert.equal game.getPlayerTeam('abc'), 1

    it "Should add player to team with least players", ->
      game.players = [{team: 0}]
      assert.equal game.getPlayerTeam(), 1

  describe "findFirstBot", ->

  describe "playerJoin", ->
    player = null
    addPlayerArgs = null
    callbackArgs = null
    socket = "SockYea!"
    socketArgs = null
    joinedGame = false
    beforeEach ->
      player = new Player();
      callback = ->
        callbackArgs = arguments
      game.addPlayer = ->
        addPlayerArgs = arguments;
      player.setSocket = ->
        socketArgs = arguments;
      player.joinGame = ->
        joinedGame = true
      player.sendDetails = -> assert true
      game.dispatcher = new Dispatcher();
      game.kickPlayer = -> assert true
      game.isCustomGame = -> true
      game.broadcastDetails = sinon.stub()
      game.playerJoin(player, socket, callback)

    it "Should call addplayer with the player", ->
      assert addPlayerArgs?
      assert.deepEqual addPlayerArgs[0], player

    it "Should set players team and socket and call joinGame", ->
      assert.equal player.team, 0
      assert socketArgs?
      assert.equal socketArgs[0], socket
      assert.equal joinedGame, true

    it "Should add players to teams equally as more are added", ->

    it "Should call sendDetails", ->
      sendDetailsCalled = false
      player.sendDetails = ->
        sendDetailsCalled = true
      game.playerJoin player, socket
      assert.equal sendDetailsCalled, true

    it "Should trigger broadcastDetails", ->
      assert game.broadcastDetails.calledOnce

    it "Should report game is full if the game is in the lobby and total players is more than max and there are no bots in the game", ->
      game.data.state = config.states.lobby
      game.maxPlayers = 6
      game.totalPlayers = 6
      game.players = []
      for i in [0...6]
        game.players.push({isBot: false})
      emitArgs = null
      socket =
        emit: () -> emitArgs = arguments
      game.playerJoin(player, socket)
      assert emitArgs?
      assert.equal emitArgs[0], netMsg.game.error
      assert.deepEqual emitArgs[1], {error: netMsg.game.full}

    it "Should not report game is full if it is at max players but there are bots in the game", ->
      game.data.state = config.states.lobby
      game.maxPlayers = 6
      game.totalPlayers = 6
      game.players = []
      for i in [0...6]
        game.players.push({isBot: !!(i % 2)})
      emitArgs = null
      socket =
        emit: () -> emitArgs = arguments
      game.playerJoin(player, socket)
      assert !emitArgs?

    it "Should not report game is full if the game has started and total players is more than max", ->
      game.data.state = config.states.started
      game.maxPlayers = 6
      game.totalPlayers = 6
      emitArgs = null
      socket =
        emit: () -> emitArgs = arguments
      game.playerJoin(player, socket)
      assert !emitArgs?

    it "Should call syncData on player if gamestate is begun", ->
      calledSyncData = false
      player.syncData = -> calledSyncData = true

      game.data.state = config.states.init
      game.playerJoin(player, socket)
      assert.equal calledSyncData, false

      game.data.state = config.states.begun
      game.playerJoin(player, socket)
      assert.equal calledSyncData, true

  describe "addPlayer", ->
    beforeEach ->
      game.dispatcher = new Dispatcher();

    
  describe "deletePlayer", ->
    it "Should return false immediately if the game is finished", ->
      ### This is here because sometimes clients will send a disconnect 
      after the game is alredy over and make the game crash due to everything 
      being deleted already. ###
      game.data.state = config.states.finished
      player = {id: 5, disconnect: ->}
      game.players = [player]
      funcReturn = game.deletePlayer(player)
      assert.equal funcReturn, false

    it "Should end the game if the game is in lobby state and there are no players left", ->
      endCalled = false
      game.end = ->
        endCalled = true
      game.data.state = config.states.lobby
      game.totalPlayers = 0
      game.deletePlayer("testPlayerId")
      assert.equal endCalled, true

  describe "playerConnected", ->
    it "should set gameEndCheck to null", ->
      game.gameEndCheck = "test"
      game.playerConnected({id: 5})

      assert.equal game.gameEndCheck, null


  describe "playerDisconnected", ->
    beforeEach ->
      game.checkIfGameShouldEnd = -> assert true

    it "Should create a gameEndCheck if all players are disconnected and state is more than lobby", ->
      game.data.state = config.states.begun
      game.players = [{id: 5, disconnected: true}, {id: 6, disconnected: true}]
      game.playerDisconnected(null)
      assert game.gameEndCheck?

    it "Should not create a gameEndCheck if all players are disconnected and state is lobby", ->
      game.data.state = config.states.lobby
      game.players = [{id: 5, disconnected: true}, {id: 6, disconnected: true}]
      game.playerDisconnected(null)
      assert.equal game.gameEndCheck, null

    it "Should not create a gameEndCheck if all players are disconnected and state is started", ->
      game.data.state = config.states.started
      game.players = [{id: 5, disconnected: true}, {id: 6, disconnected: true}]
      game.playerDisconnected(null)

      assert.equal game.gameEndCheck, null

    it "Sould not create a gameEndCheck if players list has connected people in it", ->
      game.data.state = config.states.begun
      game.players = [{id: 5, disconnected: false}, {id: 6, disconnected: true}]
      game.playerDisconnected(null)
      assert.equal game.gameEndCheck, null

    it "Should not create a gameEndCheck if one already exists", ->
      game.gameEndCheck = {mew: 5}
      game.data.state = config.states.begun
      game.players = [{id: 5, disconnected: true}, {id: 6, disconnected: true}]
      game.playerDisconnected(null)
      assert.deepEqual game.gameEndCheck, {mew: 5}



  describe "addBot", ->
    it "Should return false if the state is not lobby", ->
      game.data.state = config.states.started
      callback = sinon.stub()
      game.addBot({}, callback);
      assert callback.calledOnce

    it "Should send a request to the bot master to add a bot to this game", ->           
      # game.data.state = config.states.lobby
      # game.addBot();

  describe "getPlayers", ->
    it "Should get a list of players containing id, name, race, team for each", ->
      playersList = [
        {
          id: 0,
          name: "supa",
          race: "shadow",
          team: 0
          isBot: false
          ready: false
          loaded: false
        },
        {
          id: 1,
          name: "yoohoo",
          race: "druids",
          team: 1
          isBot: false
          ready: false
          loaded: false
        }
      ]
      game.players = playersList
      playersReturn = game.getPlayers()
      assert.deepEqual playersList, playersReturn

  describe "update", ->
  
  describe "checkIfGameShouldEnd", ->
    beforeEach ->
      game.end = -> assert true

    it "Should set gameEndCheck to null", ->
      game.gameEndCheck = {mew: 4}
      game.checkIfGameShouldEnd()
      assert.equal game.gameEndCheck, null

    it "Should end the game if all players are disconnected", ->
      game.players = [{id: 1, disconnected: true}]
      endCalled = false
      game.end = ->
        endCalled = true
      game.checkIfGameShouldEnd();

      assert.equal endCalled, true

    it "Should not end the game if players have reconnected", ->
      game.players = [{id: 6, disconnected: false}, {id: 8, disconnected: true}]
      endCalled = false
      game.end = ->
        endCalled = true
      game.checkIfGameShouldEnd();
      assert.equal endCalled, false

  describe "updatePlayerProfilesAtEnd", ->
    it "Should callback false if the winningTeam is undefined", (done) ->
      game.updatePlayerProfilesAtEnd undefined, (err, result) ->
        assert.equal result, false
        done()

    it "Should call calculateEloChange if winningTeam is 0", (done) ->
      sinon.stub(game, "calculateEloChange")
      game.updatePlayerProfilesAtEnd 0, (err, result) ->
      assert game.calculateEloChange.calledWith(0)
      game.calculateEloChange.restore()
      done()

    it "Should call calculateEloChange if winningTeam is 1", (done) ->
      sinon.stub(game, "calculateEloChange")
      game.updatePlayerProfilesAtEnd 1, (err, result) ->
      assert game.calculateEloChange.calledWith(1)
      game.calculateEloChange.restore()
      done()



  describe "calculateEloChange", ->
    it "Should return 8 for winning team 0 if elos are 1600 and 1400", (done) ->
      sinon.stub(game, 'getTeamElos').callsArgWith(0, null, [1600, 1400])
      game.calculateEloChange 0, (err, eloChange) ->
        assert.equal(eloChange, 8)
        done()

    it "Should return 8 for winning team 1 if elos are 1400 and 1600", (done) ->
      sinon.stub(game, 'getTeamElos').callsArgWith(0, null, [1400, 1600])
      game.calculateEloChange 1, (err, eloChange) ->
        assert.equal(eloChange, 8)
        done()

    it "Should return 24 for winning team 0 if elos are 1600 and 1400", (done) ->
      sinon.stub(game, 'getTeamElos').callsArgWith(0, null, [1600, 1400])
      game.calculateEloChange 1, (err, eloChange) ->
        assert.equal(eloChange, 24)
        done()

    it "Should return 24 for winning team 0 if elos are 1400 and 1600", (done) ->
      sinon.stub(game, 'getTeamElos').callsArgWith(0, null, [1400, 1600])
      game.calculateEloChange 0, (err, eloChange) ->
        assert.equal(eloChange, 24)
        done()


  describe "getTeamElos", ->
    it "Should return the average elo for each team", (done) ->
      players = [
        {id: 1, team: 0, get: -> 1100}
        {id: 2, team: 0, get: -> 1200}
        {id: 3, team: 0, get: -> 1300}
        {id: 4, team: 1, get: -> 1700}
        {id: 5, team: 1, get: -> 1800}
        {id: 6, team: 1, get: -> 1750}
      ]
      game.players = players
      sinon.stub(UserMock, 'findById', (id, callback) -> callback(null, players[id-1]))
      game.getTeamElos (err, teamElos) ->
        if err then return done(err)
        assert.equal(teamElos[0], 1200)
        assert.equal(teamElos[1], 1750)
        UserMock.findById.restore()
        done()

  describe "allocatePlayerTeams",  ->
    it "Should put 3 players on team 1 and 3 on team 2, grouped with those they matchmade with", (done) ->
      game.matchId = "123"
      data = [
        {userIds: ['a', 'b', 'c']}
        {userIds: ['d', 'e', 'f']}
      ]
      queuers = data.map((q) -> {data: q, get: (name) -> @data[name]})
      sinon.stub(QueuerMock, 'findAllByMatchId').callsArgWith(1, null, queuers)
      game.allocatePlayerTeams (err, result) ->
        assert.deepEqual game.playerTeamAllocations, {a: 0, b: 0, c: 0, d: 1, e: 1, f: 1}
        QueuerMock.findAllByMatchId.restore()
        done()

    it "Should work with teams of 2 + 1", (done) ->
      game.matchId = "123"
      data = [
        {userIds: ['a', 'b']}
        {userIds: ['d', 'e']}
        {userIds: ['c']}
        {userIds: ['f']}
      ]
      queuers = data.map((q) -> {data: q, get: (name) -> @data[name]})
      sinon.stub(QueuerMock, 'findAllByMatchId').callsArgWith(1, null, queuers)
      game.allocatePlayerTeams (err, result) ->
        assert.deepEqual game.playerTeamAllocations, {a: 0, b: 0, c: 0, d: 1, e: 1, f: 1}
        QueuerMock.findAllByMatchId.restore()
        done()


    it "Should work with teams of 2 + 1 in a strange order", (done) ->
      game.matchId = "123"
      data = [
        {userIds: ['c']}
        {userIds: ['a', 'b']}
        {userIds: ['d', 'e']}
        {userIds: ['f']}
      ]
      queuers = data.map((q) -> {data: q, get: (name) -> @data[name]})
      sinon.stub(QueuerMock, 'findAllByMatchId').callsArgWith(1, null, queuers)
      game.allocatePlayerTeams (err, result) ->
        assert.deepEqual game.playerTeamAllocations, {a: 0, b: 0, c: 0, d: 1, e: 1, f: 1}
        QueuerMock.findAllByMatchId.restore()
        done()

  describe "allocateRandomRaces", ->
    it "Should set all players who have a null race to a valid race", ->
      game.isCustomGame = -> false
      game.players = [
        {race: 'shadow', team: 0}
        {race: 'crusaders', team: 0}
        {race: null, team: 0, setRace: (@race) ->}
      ]
      game.allocateRandomRaces()
      assert.equal(game.players[0].race, 'shadow')
      assert.equal(game.players[1].race, 'crusaders')
      assert(game.players[2].race != null)













