#global ts
GameEntity = require("./game-entity.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")
towerConfig = require("config/towers")

_ = require("lodash")

class TowerOverlay extends GameEntity
  ctype: GameEntity.CTYPE.TOWEROVERLAY
  name: "towerOverlay"

  constructor: (x, y, settings) ->
    @reset()
    @towerType = settings.id
    super(x, y, settings)
    @loadLevelZero()
    @loadAnimations()

  reset: ->
    super()
    @towerType = null
    @imageName = null
    @buildsOnRoads = false
    @cost = 0
    @range = 0
    @auraRange = 0
    @alpha = 0.5

  getLevelSettings: (level) ->
    towerDetails = towerConfig[@towerType]
    return towerDetails.levels[level]

  loadLevelZero: ->
    levelSettings = @getLevelSettings(0)
    for name, setting of levelSettings
      if name in ['range'] #Add any levelSettings here that will be used by this towerOverlay
        if typeof(setting) == "object" && @[name]
          @[name] = _.extend(@[name], setting)
        else
          @[name] = setting

  loadAnimations: ->
    @animSheet = ts.game.cache.getAnimationSheet('towers/' + @imageName, config.towers.width, config.towers.height, config.towerOverlay.zIndex)
    @size = {x: config.towers.width, y: config.towers.height}
    @offset = {x: 8, y: 16}
    @addAnim "idle", 0.1, [0]

  draw: ->
    if @_destroyed
      return false
    #Radius circle
    circlePos = {x: @pos.x + (config.towers.width / 2) - @offset.x, y: @pos.y + (config.towers.height / 2) - @offset.y}

    graphics = ts.game.graphics

    playerTeam = 0
    hasEnoughGold = false
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player?
        playerTeam = player.getTeam();
        hasEnoughGold = player.getGold() >= @cost
    takenLevel = 0
    if @buildsOnRoads
      takenLevel = 1
    isPositionTaken = ts.game.towerManager.isPositionTaken(@pos.x / config.tileSize, @pos.y / config.tileSize, playerTeam, takenLevel)

    if isPositionTaken
      graphics.beginFill(0xC82424, 0.3)
      graphics.lineStyle(1, 0x991010, 1);
    else if !hasEnoughGold
      graphics.beginFill(0xC8C824, 0.3)
      graphics.lineStyle(1, 0x999910, 1);
    else
      graphics.beginFill(0x24C824, 0.3)
      graphics.lineStyle(1, 0x109910, 1);
    radius = @range * config.tileSize
    graphics.drawCircle(circlePos.x, circlePos.y, radius)
    graphics.endFill()
    graphics.lineStyle(0)
    if @auraRange
      graphics.beginFill(0x2424C8, 0.3)
      graphics.lineStyle(1, 0x101099, 1);
      radius = @auraRange * config.tileSize
      graphics.drawCircle(circlePos.x, circlePos.y, radius)
      graphics.endFill()
      graphics.lineStyle(0)

    super();

module.exports = TowerOverlay
