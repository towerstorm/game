_ = require 'lodash'

class ServerGameMock 
  towerQueueCall: null
  sendGoldQueueCall: null
  minionQueueCall: null
  data: {}

  constructor: ->
    @ts.game.queueMinion = _.bind(@ts.game.queueMinion, @)
    @ts.game.queueSendGold = _.bind(@ts.game.queueSendGold, @)
    @ts.game.towerManager.queueTower = _.bind(@ts.game.towerManager.queueTower, @)

  ig:
    getCurrentTick: ->
      return 4; #Very Random Number

    game:
      towerManager: 
        queueTower: ->
          @towerQueueCall = arguments

      queueSendGold: ->
        @sendGoldQueueCall = arguments

      queueMinion: ->
        @minionQueueCall = arguments

  getCurrentTick: =>
    return @currentTick

  getTicks: =>
    return @ticks

  get: (name) => @data[name]
  set: (name, value) => @data[name] = value






module.exports = ServerGameMock