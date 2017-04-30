#global ts
GameEntity = require("./game-entity.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")

class MinionOverlay extends GameEntity
  ctype: GameEntity.CTYPE.MINIONOVERLAY
  name: "minionOverlay"

  constructor: (x, y, settings) ->
    @reset()
    super(x, y, settings)
    @loadAnimations()

  reset: ->
    super()
    @minionType = null
    @imageName = null
    @cost = 0
    @souls = 0
    @animSpeed = null
    @alpha = 0.5

  loadAnimations: ->
    @width = @width || config.minions.width
    @height = @height || config.minions.height
    @size = {x: @width, y: @height}
    @animSheet = ts.game.cache.getAnimationSheet('minions/' + @imageName, @width, @height, config.minionOverlay.zIndex)
    @offset = {x: ((@width - 48) / 2), y: ((@height - 48) / 2)}
    animSpeed = @animSpeed || 0.1
    for own animName, animFrames of @frames
      @addAnim(animName, animSpeed, animFrames)
    @currentAnim = @anims.down

  draw: ->
    if @_destroyed
      return false
    circlePos = {x: @pos.x + (@width / 2) - @offset.x, y: @pos.y + (@height / 2) - @offset.y}

    graphics = ts.game.graphics

    playerTeam = 0
    hasEnoughGold = false
    hasEnoughSouls = false
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player?
        playerTeam = player.getTeam();
        hasEnoughGold = player.getGold() >= @cost
        hasEnoughSouls = player.getSouls() >= @souls
    isValidSpawnPoint = ts.game.minionManager.isValidSpawnPoint(@pos.x / config.tileSize, @pos.y / config.tileSize, playerTeam)

    if !isValidSpawnPoint
      graphics.beginFill(0xC82424, 0.3)
      graphics.lineStyle(1, 0x991010, 1);
    else if !hasEnoughGold || !hasEnoughSouls
      graphics.beginFill(0xC8C824, 0.3)
      graphics.lineStyle(1, 0x999910, 1);
    else
      graphics.beginFill(0x24C824, 0.3)
      graphics.lineStyle(1, 0x109910, 1);
    radius = 1 * config.tileSize
    graphics.drawCircle(circlePos.x, circlePos.y, radius)
    graphics.endFill()
    graphics.lineStyle(0)

    super();

module.exports = MinionOverlay
