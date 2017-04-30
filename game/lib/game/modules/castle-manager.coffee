Castle = require("../entities/castle.coffee")
GameEntity = require("../entities/game-entity.coffee")
SpawnPoint = require("../entities/spawn-point.coffee")
QuadTree = require("./quad-tree.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")
maps = require("../../../../config/maps")

class CastleManager
  constructor: () ->
    @reset()
    @quadTree = new QuadTree(config.tileSize);

  reset: ->
    @castles = []
    @quadTree = null

  begin: (mapId) ->
    @bindDispatcher()
    map = _.clone(maps[mapId])
    if map?
      @createCastles(map);
      @createSpawnPoints(map);

  bindDispatcher: ->
    ts.game.dispatcher.on gameMsg.minionReachedNode, (minion) =>
      @checkIfMinionHitCastle(minion)

  createCastles: (map) ->
    if !map.castles?
      return false
    for castleInfo in map.castles
      xPos = castleInfo.x * config.tileSize
      yPos = castleInfo.y * config.tileSize
      delete castleInfo.x; delete castleInfo.y; #don't need to send them
      castle = ts.game.spawnEntity(GameEntity.CTYPE.CASTLE, xPos, yPos, castleInfo)
      @quadTree.addEntity(castle)
      @castles.push(castle)

  createSpawnPoints: (map) ->
    if !map.spawnPoints?
      return false
    spawnPointNum = 0 
    for spawnPointInfo in map.spawnPoints
      if spawnPointInfo.visible != false
        xPos = spawnPointInfo.x * config.tileSize
        yPos = spawnPointInfo.y * config.tileSize
        if spawnPointInfo.team == 0
          spawnPointInfo.imageName = "spawn-point-red.png"
        else
          spawnPointInfo.imageName = "spawn-point-blue.png"
        spawnPointInfo.size = {x: 33, y: 33}
        spawnPointInfo.offset = {x: -8, y: -8}
        spawnPointInfo.spawnPointNum = spawnPointNum
        delete spawnPointInfo.x; 
        delete spawnPointInfo.y; 
        spawnPointInfo = ts.game.spawnEntity(GameEntity.CTYPE.SPAWNPOINT, xPos, yPos, spawnPointInfo)
        spawnPointNum++

  checkIfMinionHitCastle: (minion) ->
    castle = @findCastle(minion.pos.x, minion.pos.y)
    if !castle?
      return false
    castle.receiveDamage(minion.souls, minion)
    minion.lastDamageSource = null
    minion.kill();

  findCastle: (xPos, yPos) ->
    for castle in @castles
      if !castle._killed && castle.pos.x == xPos && castle.pos.y == yPos
        return castle
    return null

  update: () ->

  getCastlesInArea: (xPos, yPos, rangeScaled) ->
    return @quadTree.getEntities(xPos, yPos, rangeScaled)

module.exports = CastleManager
