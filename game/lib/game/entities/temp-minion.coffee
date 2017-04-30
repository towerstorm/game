###
  The temp-minion is for hiding lag, this is spawned instantly when the player clicks
  create minion then it is destroyed and replaced with a real minion when the server
  confirms the spawn
###
Timer = require("../../engine/timer.coffee")
GameEntity = require("./game-entity.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")

class TempMinion extends GameEntity
  ctype: GameEntity.CTYPE.TEMPMINION

  constructor: (x, y, settings) ->
    @reset()
    super(x, y, settings)
    @width = @width || config.minions.width
    @height = @height || config.minions.height
    @offset = {x: ((@width - 48) / 2), y: ((@height - 48) / 2)}
    if @moveType == "ground"
      @offset.y += config.minions.groundVerticalOffset
    if @moveType == "air"
      @offset.y += config.minions.airVerticalOffset
    @size = {x: @width, y: @height}
    @loadAnimations()
    @currentAnim = @anims.down
    @spawnTick = ts.getCurrentTick()

  reset: ->
    super()
    @race = null
    @spawnTick = 0
    @cost = 0
    @speed = 0
    @souls = 0
    @minionType = null
    @imageName = null
    @moveType = null

  loadAnimations: ->
    imageName = 'minions/' + @imageName
    @zIndex = @zIndex || config.minions.zIndex
    @animSheet = ts.game.cache.getAnimationSheet(imageName, @width, @height, @zIndex)
    @offset = {x: ((@width - 48) / 2), y: ((@height - 48) / 2)}
    if @moveType == "ground"
      @offset.y += config.minions.groundVerticalOffset
    if @moveType == "air"
      @offset.y += config.minions.airVerticalOffset
    animSpeed = @animSpeed || 0.1
    for own animName, animFrames of @frames
      @addAnim(animName, animSpeed, animFrames)
    @currentAnim = @anims.down

  update: () ->
    super();
    @checkForSuicide()

  draw: () ->
    @fadeIn()
    super();

  fadeIn: () ->
    fadeInTicks = ts.game.getEstimatedMaxLag() / Timer.constantStep
    ticksSinceSpawn = ts.getCurrentTick() - @spawnTick
    alpha = Math.min(0.8, ticksSinceSpawn / fadeInTicks)
    @animSheet.setAlpha(alpha)

  checkForSuicide: () ->
    if @_killed
      return false
    timeUntilDeath = config.minions.suicideTime + ts.game.getEstimatedMaxLag()
    ticksUntilDeath = timeUntilDeath / Timer.constantStep
    if ts.getCurrentTick() > (@spawnTick + ticksUntilDeath)
      @suicide();

  suicide: ->
    if @_killed
      return false
    ts.game.dispatcher.emit gameMsg.tempMinionSuicide, @minionType

  kill: ->
    super();

module.exports = TempMinion
