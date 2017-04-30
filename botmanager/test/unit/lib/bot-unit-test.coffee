Bot = require '../../../lib/bot'
Dispatcher = require '../../../lib/dispatcher'
assert = require 'assert'
gameMsg = require 'config/game-messages'
netMsg = require 'config/net-messages'
races = require 'config/races'
config = require 'config/botmanager'
netconfig = require 'config/netconfig'
_ = require 'lodash'
sinon = require 'sinon'
SocketMock = require '../mocks/socket-mock.coffee'
nock = require 'nock'
uuid = require 'node-uuid'
util = require 'util'

delay = (time, func) -> setTimeout(func, time)

describe "Bot", ->
  bot = null

  beforeEach ->
    bot = new Bot();
    bot.dispatcher = new Dispatcher()
    bot.dispatcher.reset()
    bot.socket = {}

  describe "init", ->

  describe "pickRace", ->
    it "Should not return one of the excluded races", ->
      races = _.keys(races)
      excludedRaces = ['shadow', 'elementals']
      assert(bot.pickRace(excludedRaces) in races)
      assert(bot.pickRace(excludedRaces) not in excludedRaces)

  describe "authenticate", ->

  describe "createGame", ->

  describe "joinGame", ->

  describe "createLobby", ->

  describe "joinLobby", ->

  describe "queue", ->

  describe "waitForQueue", ->

  describe "waitForMatch", ->
    queuerId = null
    beforeEach ->
      queuerId = uuid.v4()
      bot.userId = uuid.v4()
      bot.lobbySocket = new SocketMock()
      bot.queuerId = queuerId
      bot.log = {
        info: -> console.log.apply(console, arguments)
      }

    it "Should not call confirm twice if it gets queue.details where the bots state is confirming and they aren't in accepted twice", (done) ->
      confirm = nock(netconfig.lobby.url).get('/queue/' + queuerId + '/accept').times(1).reply(200, 'rar')
      totalAccepts = 0
      bot.log.info = (msg) ->
        if msg.match(/Accepted match/)
          totalAccepts++
      bot.waitForMatch()
      bot.lobbySocket.trigger('queue.details', {id: queuerId, state: 'confirming', confirmedUserIds: []})
      bot.lobbySocket.trigger('queue.details', {id: queuerId, state: 'confirming', confirmedUserIds: []})
      delay 100, ->
        assert confirm.isDone()
        assert.equal totalAccepts, 1
        done()

    it "Should not call joinGame twice if it gets queue.details where state is found twice", (done) ->
      totalJoins = 0
      bot.joinGame = ->
        totalJoins++
      bot.waitForMatch()
      bot.lobbySocket.trigger('queue.details', {id: queuerId, state: 'found', game: {}})
      bot.lobbySocket.trigger('queue.details', {id: queuerId, state: 'found', game: {}})
      delay 100, ->
        assert.equal totalJoins, 1
        done()

    it "Should set internalState to null if the bot goes back to searching", (done) ->
      bot.waitForMatch()
      bot.internalState = "confirmed"
      bot.lobbySocket.trigger('queue.details', {id: queuerId, state: 'searching'})
      delay 100, ->
        assert.equal bot.internalState, null
        done()









  describe "getServerUrl", ->

  describe "getSessionId", ->

  describe "afterLobbyAuth", ->

  describe "getRacesOnTeam", ->
    it "Should return the number of unique races on the team", ->
      players = {
        player1: {team: 0, race: 'shadow'}
        player2: {team: 1, race: 'droids'}
        player3: {team: 1, race: 'elementals'}
        player4: {team: 1, race: 'elementals'}
        player5: {team: 0, race: 'crusaders'}
      }
      assert.deepEqual(bot.getRacesOnTeam(players, 0), ['shadow', 'crusaders'])
      assert.deepEqual(bot.getRacesOnTeam(players, 1), ['droids', 'elementals'])

  describe "receivedGameDetails", ->

  describe "bindSockets", ->
    beforeEach ->
    it "Should not crash if player details were received when game is null", (done) ->
      bot.game = null
      bot.socket = new SocketMock()
      bot.bindSockets ->
        assert true
      bot.socket.trigger netMsg.player.details, {name: 'mew'}
      delay 100, ->
        done()


  describe "bindDispatcher", ->
    it "Should bind action.collectGem to collectGem", ->
      collectGemArgs = null
      bot.collectGem = ->
        collectGemArgs = arguments
      bot.bindDispatcher()
      bot.dispatcher.emit config.messages.collectGem, 5
      assert collectGemArgs?
      assert.equal collectGemArgs[0], 5

  describe "disconnected", ->

  describe "end", ->

  describe "gameStarted", ->

  describe "reportLoaded", ->

  describe "beginGame", ->
    it "Should not crash if game is null", ->
      bot.game = null
      bot.beginGame({})

  describe "getCurrentTick", ->

  describe "processTickData", ->

  describe "placeTower", ->

  describe "upgradeTower", ->
    socketEmitArgs = null
    beforeEach ->
      socketEmitArgs = null
      bot.emit = ->
        socketEmitArgs = arguments

    it "Should return not emit if type is null", ->
      bot.upgradeTower(null)
      assert.equal socketEmitArgs, null

    it "Should emit with a valid type", ->
      bot.upgradeTower({xPos: 1, yPos: 4})
      assert.equal socketEmitArgs[0], 'upgradeTower'
      assert.deepEqual socketEmitArgs[1], {xPos: 1, yPos: 4}


  describe "placeMinion", ->
    socketEmitArgs = null
    beforeEach ->
      socketEmitArgs = null
      bot.emit = ->
        socketEmitArgs = arguments

    it "Should return not emit if type is null", ->
      bot.placeMinion(null)
      assert.equal socketEmitArgs, null

    xit "Should emit with a valid type", ->
      bot.placeMinion(1, 2, 'goblin')
      console.log("socket emit args are: ", socketEmitArgs)
      assert.equal socketEmitArgs[0], 'placeMinion'
      assert.equal socketEmitArgs[1], 1
      assert.equal socketEmitArgs[2], 2
      assert.equal socketEmitArgs[3], 'goblin'

  describe "collectGem", ->
    it "Should emit a socket message to collect a gem", ->
      emitArgs = null
      bot.emit = ->
        emitArgs = arguments
      bot.collectGem(5)
      assert emitArgs?
      assert.equal emitArgs[0], netMsg.game.collectGem
      assert.equal emitArgs[1], 5

  describe "update", ->
    beforeEach ->
      bot.gameState = config.states.begun
      bot.lastTick = 4
      bot.getCurrentTick = -> 5

    it "Should return false if the gameState is finished", ->
      bot.gameState = config.states.finished
      assert.equal bot.update(), false

    it "Should set lastTick to currentTick", ->
      bot.brain.getNextTurn = -> {}
      bot.update()
      assert.equal bot.lastTick, 5

    it "Should call placeMinion when action is placeMinion", ->
      bot.brain.getNextTurn = -> {action: config.actions.placeMinion, settings: {x: 1, y: 2, type: 'goblin'}}
      placeMinionArgs = null
      bot.placeMinion = ->
        placeMinionArgs = arguments
      bot.update()
      assert placeMinionArgs
      assert.equal placeMinionArgs[0], 1
      assert.equal placeMinionArgs[1], 2
      assert.equal placeMinionArgs[2], 'goblin'

    it "Should call placeTower when action is buildTower", ->
      bot.brain.getNextTurn = -> {action: config.actions.buildTower, settings: {x: 1, y: 5, type: 'crossbow'}}
      placeTowerArgs = null
      bot.placeTower = ->
        placeTowerArgs = arguments
      bot.update()
      assert placeTowerArgs
      assert.equal placeTowerArgs[0], 1
      assert.equal placeTowerArgs[1], 5
      assert.equal placeTowerArgs[2], 'crossbow'

    it "Should call upgradeTower when action is upgradeTower", ->
      bot.brain.getNextTurn = -> {action: config.actions.upgradeTower, settings: {x: 1, y: 5, type: 'crossbow'}}
      upgradeTowerArgs = null
      bot.upgradeTower = ->
        upgradeTowerArgs = arguments
      bot.update()
      assert upgradeTowerArgs
      assert.deepEqual upgradeTowerArgs[0], {x: 1, y: 5, type: 'crossbow'}

  describe "emit", ->














