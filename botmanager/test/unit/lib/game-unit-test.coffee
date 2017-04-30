Game = require '../../../lib/game'
Dispatcher = require '../../../lib/dispatcher'
config = require 'config/botmanager'
assert = require 'assert'
gameMsg = require 'config/game-messages'

describe "Game", ->
  game = null

  beforeEach ->
    game = new Game();
    game.dispatcher = new Dispatcher()
    game.dispatcher.reset()
    game.ts = 
      game:
        dispatcher: new Dispatcher()
    game.ts.game.dispatcher.reset()

  describe "beginGame", ->

  describe "getCurrentTick", ->

  describe "processTickData", ->
    it "Should broadcast any tower placements to the bot", ->
      data = 
        towers: [{xPos: 5, yPos: 7, settings: {ownerId: 1}}, {xPos: 8, yPos: 9, settings: {ownerId: 2}}]

      dispatcherArgs = []
      game.dispatcher = 
        emit: ->
          dispatcherArgs.push arguments

      game.processTickData 3, data, (err, res) ->
        assert.equal dispatcherArgs[0][0], config.messages.towerCreated
        assert.equal dispatcherArgs[0][1], 5
        assert.equal dispatcherArgs[0][2], 7

        assert.equal dispatcherArgs[1][0], config.messages.towerCreated
        assert.equal dispatcherArgs[1][1], 8
        assert.equal dispatcherArgs[1][2], 9





