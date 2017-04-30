###
  The temp tower is just a static tower that hides lag. It is placed when the player
  builds a tower but doesn't do anything until the server confirms the tower was built then
  kills this temp tower and replaces it with a real one.
###
Timer = require("../../engine/timer.coffee")
GameEntity = require("./game-entity.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")

class TempTower extends GameEntity
  ctype: GameEntity.CTYPE.TEMPTOWER

  constructor: (x, y, settings) ->
    @reset()
    @towerType = settings.id
    super(x, y, settings)
    @zIndex = @zIndex || config.towers.zIndex
    @animSheet =  ts.game.cache.getAnimationSheet('towers/' + @imageName, config.towers.width, config.towers.height, @zIndex)
    @size = {x: config.towers.width, y: config.towers.height}
    @offset = {x: 8, y: 16}
    @addAnim("idle", 0.1, [0])
    @spawnTick = ts.getCurrentTick()
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player?
        player.addTempSpend(@cost)

  reset: ->
    super()
    @cost = 0
    @imageName = null
    @towerType = null

  update: () ->
    super();
    @checkForSuicide()

  draw: () ->
    super();

  checkForSuicide: () ->
    if @_killed
      return false
    timeUntilDeath = config.towers.suicideTime + ts.game.getEstimatedMaxLag()
    ticksUntilDeath = timeUntilDeath / Timer.constantStep
    if ts.getCurrentTick() > (@spawnTick + ticksUntilDeath)
      @suicide();

  suicide: ->
    xCoord = Math.floor(@pos.x / config.tileSize)
    yCoord = Math.floor(@pos.y / config.tileSize)
    ts.game.dispatcher.emit gameMsg.tempTowerSuicide, xCoord, yCoord

  kill: ->
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player?
        player.addTempSpend(-@cost)
    super();

module.exports = TempTower
