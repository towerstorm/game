### 
For testing the server side player, not the in game player. 
###

_ = require 'lodash'
assert = require 'assert'
sinon = require 'sinon'
config = require 'config/gameserver'
Player = require '../../../lib/player'
ServerGameMock = require './server-game-mock'
SocketMock = require '../socket-mock'
gameMsg = require 'config/game-messages'
general = require 'config/gameserver'
netMsg = require 'config/net-messages'
minions = require 'config/minions'

serverGameMock = new ServerGameMock();

player = null

describe "Server Player", ->
  beforeEach ->
    player = new Player();
    player.id = 17;
    player.socket = new SocketMock();
    player.getRace = -> "crusaders"
    player.game = {
      userReady: ->
      ig: {
        getCurrentTick: -> 1
        game: {

        }
      }
    }
    player.log = {
      info: ->
      error: ->
    }

  describe "constructor", ->
    it "Should have disconnected set to false by default", ->
      assert.equal player.disconnected, false

  describe "joinGame", ->
    calledSyncData = false
    beforeEach ->
      calledSyncData = false
      player.syncData = ->
        calledSyncData = true

    it "Should set player.disconnected to false", ->
      player.disconnected = true
      player.bindGameSockets = ->
        assert true

      player.joinGame(serverGameMock)

      assert.equal player.disconnected, false

  describe "syncData", ->
    syncGameMock = null
    beforeEach ->
      syncGameMock = new ServerGameMock();
      player.game = syncGameMock

    it "Should retrieve all ticks that have happened so far from the game", ->
      calledGetTicks = false
      syncGameMock.getTicks = ->
        calledGetTicks = true

      calledGetCurrentTick = false
      syncGameMock.getCurrentTick = ->
        calledGetCurrentTick = true

      calledGetPlayers = false
      syncGameMock.getPlayers = ->
        calledGetPlayers = true

      player.syncData()
      assert.equal calledGetTicks, true
      assert.equal calledGetCurrentTick, true
      assert.equal calledGetPlayers, true

    it "Should send the data to the player in a formatted syncData packet tick playerId, players and ticks", ->
      syncGameMock.currentTick = 18;
      syncGameMock.ticks = {
        '4': {
          towers: [{xPos: 5, yPos: 10, settings: "CoolTower"}]
        }
        '15': {
          towers: [{xPos: 4, yPos: 15}],
          minions: [{}]
        }
      }

      syncGameMock.getPlayers = ->
        return {
          "This": "Is some players"
        }

      syncGameMock.data.settings = {
        mapId: 4
        mode: "PVP"
        difficulty: 0
        targetTime: 0
        incomeMultiplier: 1
        linearGold: true

      }

      expectedSyncData = {
        'ticks': syncGameMock.ticks
        'playerId': player.id
        'players': syncGameMock.getPlayers()
        'settings':
          'mapId': 4
          'mode': "PVP"
          'difficulty': 0
          'targetTime': 0
          'incomeMultiplier': 1
          'linearGold': true
      }

      player.syncData()

      assert player.socket.socketMessages[netMsg.game.syncData]?
      syncMessage = player.socket.socketMessages[netMsg.game.syncData]

      assert.equal syncMessage[0], 18
      assert.deepEqual syncMessage[1], expectedSyncData



  describe "setTeam", ->
    it "Should set the players team", ->
      player.team = 0
      team = 1

      win = player.setTeam team

      assert.equal win, true
      assert.equal player.team, team


    it "Should return false if the players team is not an integer", ->
      win = player.setTeam "invalid"

      assert.equal win, false

  describe "disconnect", ->
    it "Should set the disconnected flag on the player to true", ->
      player.disconnected = false
      player.disconnect()

      assert.equal player.disconnected, true

  describe "sendTick", ->
    it "should return false and not emit tickData if the player is disconnected", ->
      player.disconnected = true

      sendReturn = player.sendTick 1, {test: "bleh"}
      assert.equal sendReturn, false

      assert !player.socket.socketMessages[netMsg.game.tickData]?

  describe "performAction", ->
    it "Should return false if canPerformAction is false", ->
      player.canPerformAction = -> false
      assert.equal(player.canPerformAction(), false);
      
    it "Should set lastAction to type, data", ->
      player.canPerformAction = -> true
      player.performAction("type", {mew: "yay"});
      assert.deepEqual(player.lastAction, {type: "type", data: {mew: "yay"}});

  describe "placeTower", ->
    towerQueueCall = null
    towerSettings = null
    beforeEach ->
      towerQueueCall = null
      towerSettings = {towerType: 'crossbow'}
      player.state = config.states.begun
      player.lastAction = null
      player.race = "crusaders"

    it "Should set lastAction for this player", ->
      player.placeTower(10, 20, "crossbow")
      assert.equal(player.lastAction.type, "towers");
      assert.deepEqual(player.lastAction.data, {xPos: 10, yPos: 20, ownerId: player.id, towerType: "crossbow"});
      

  describe "upgradeTower", ->

  describe "sellTower", ->

  describe "placeMinion", ->
    gamePlayer = null
    minionType = null
    beforeEach ->
      minionType = "goblin"
      player.state = config.states.begun
      player.lastAction = null
      player.game.getMode = -> "PVP"

    it "Should not work if the state of the game is not begun", ->
      player.state = config.states.init
      player.placeMinion 1, 2, minionType
      assert.equal(player.lastAction, null)

    it "Should set lastAction for this player", ->
      player.placeMinion 1, 2, minionType
      assert.equal(player.lastAction.type, "minions")
      assert.deepEqual(player.lastAction.data, {xPos: 1, yPos: 2, ownerId: player.id, minionType: minionType});


  describe "configure", ->

    it "Should call setRace if details.race is passed through", (done) ->
      player.game = {isRaceSelected: (-> false), userReady: -> true}
      sinon.stub(player, 'setRace')
      race = "Shadow"
      player.configure {race: race}, ->
        assert player.setRace.calledWith(race)
        done()

    it "Should call setRace if details.race is passed through with details.ready and player is not already ready", (done) ->
      player.ready = false
      player.game = {isRaceSelected: (-> false), userReady: -> true}
      sinon.stub(player, 'setRace')
      sinon.stub(player, 'setReady')
      race = "Shadow"
      player.configure {race: race, ready: true}, ->
        assert player.setRace.calledWith(race)
        assert player.setReady.calledWith(true)
        done()

    it "Should call setRace if details.race is passed through with player already said they were ready", (done) ->
      player.ready = true
      player.game = {isRaceSelected: (-> false), userReady: -> true}
      sinon.stub(player, 'setRace')
      race = "Shadow"
      player.configure {race: race, ready: true}, ->
        assert player.setRace.notCalled
        done()

    it "Should call setTeam if details.team is passed through", ->
      setTeamArgs = null
      player.setTeam = ->
        setTeamArgs = arguments
      team = 1
      player.configure {team: team}, ->
        assert true
      assert setTeamArgs?
      assert.equal setTeamArgs[0], team


  describe "bindGameSockets", ->
    minionType = null
    beforeEach ->
      minionType = "goblin"
      player.state = config.states.begun
      player.lastActionTick = 0

    describe "disconnect", ->
      deleteArgs = null
      disconnectedArgs = null
      beforeEach ->
        player.bindGameSockets(serverGameMock)
        deleteArgs = null
        disconnectedArgs = null
        serverGameMock.deletePlayer = ->
          deleteArgs = arguments

        serverGameMock.playerDisconnected = ->
          disconnectedArgs = arguments

      it "Should call game.playerDisconnected", ->
        serverGameMock.data.state = config.states.begun
        player.socket.trigger netMsg.disconnect

        assert disconnectedArgs?
        assert.deepEqual disconnectedArgs[0], player


      it "Should call game.deletePlayer if the player leaves in lobby state", ->
        serverGameMock.data.state = config.states.lobby
        player.socket.trigger netMsg.disconnect

        assert deleteArgs?
        assert.deepEqual deleteArgs[0], player


      it "Should not call game.deletePlayer if the player leaves in started or begun states", ->
        serverGameMock.data.state = config.states.started
        player.socket.trigger netMsg.disconnect

        assert.equal deleteArgs, null

        serverGameMock.data.state = config.states.begun
        player.socket.trigger netMsg.disconnect

        assert.equal deleteArgs, null

      it "Should set disconnected flag on player if they leave after the game has started", ->
        serverGameMock.data.state = config.states.started
        player.socket.trigger netMsg.disconnect

        assert.equal player.disconnected, true

    describe "checkHash", ->
      it "Should do callback of ok and return true if game mode is tutorial", ->
        callbackData = null
        callback = (data) ->
          callbackData = data
        player.game =
          getMode: -> "TUTORIAL"
        player.checkHash(1, "asodijasd", callback)
        assert callbackData?
        assert.equal "{\"ok\":true}", callbackData



      

