GameEntity = require("../entities/game-entity.coffee")
QuadTree = require("./quad-tree.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")
maps = require("config/maps")

_ = require("lodash")

class TowerManager

  constructor: ->
    @reset()
    @towers = []
    @tempTowers = []
    @towerQueue = {}
    @takenPositions = {}
    @quadTree = new QuadTree(config.tileSize);

  reset: ->
    @towers = []
    @tempTowers = []
    @towerQueue = {} #A Queue for when the server says certain towers should be constructed. So that they can always be constructed at the right time.
    @takenPositions = {}
    @mapWidth = 0
    @mapHeight = 0
    @buildRestrictions = null
    @functionsBound = false
    @quadTree = null
    @tutorial =
      position: null



  #When the server sends a message down the socket to build a tower build it.
  begin: (mapId) ->
    @bindDispatcher()
    map = _.clone(maps[mapId])
    if map?
      @mapWidth = map.width;
      @mapHeight = map.height;
      @buildRestrictions = map.buildRestrictions;
      @takenPositions = map.takenPositions || {};
      @markPathsAsTaken(map.spawnPoints, map.nodePaths)

  bindDispatcher: ->
    if @functionsBound
      return false
    @functionsBound = true
    ts.game.dispatcher.on gameMsg.createdTower, (xCoord, yCoord) =>
      @markPositionTaken(xCoord, yCoord)
    ts.game.dispatcher.on gameMsg.soldTower, (tower) =>
      @soldTower(tower)
    ts.game.dispatcher.on gameMsg.action.placeTower, (xCoord, yCoord, towerType) =>
      @spawnTempTower(xCoord, yCoord, towerType)
    ts.game.dispatcher.on gameMsg.tempTowerSuicide, (xCoord, yCoord) =>
      @destroyTempTower(xCoord, yCoord)
    ts.game.dispatcher.on gameMsg.highlightPosition, (position) =>
      @tutorial.position = position

  update: ->
    ts.log.debug("In towerManager update")

  soldTower: (tower) ->
    @towers.eraseSingle(tower)
    @quadTree.removeEntity(tower)
    if tower.buildsOnRoads then takenLevel = 1 else takenLevel = 0
    @markPositionFree(tower.pos.x / config.tileSize, tower.pos.y / config.tileSize, takenLevel)

  markPathsAsTaken: (spawnPoints, paths) ->
    for path, num in paths
      path.unshift(spawnPoints[num])
      @markPathTaken(path)

  markPathTaken: (path) ->
    for i in [0...path.length]
      if path[i] && path[i+1]
        @markLineTaken(path[i], path[i+1])

  markLineTaken: (start, end) ->
    if start.x == end.x
      for i in [start.y .. end.y]
        @markPositionTaken(start.x, i, 1);
      return true
    else if start.y == end.y
      for i in [start.x .. end.x]
        @markPositionTaken(i, start.y, 1);
      return true


    return false  #Can only do straight lines

  ###
  Takes x and y as location coordinates not as pixels.
  takenLevel = 1 for road, 2 for tower. So towers that can be built on roads will work properly (and can't be built on top of each other)
  ###
  markPositionTaken: (x, y, takenLevel = 2) ->
    if !@takenPositions[x]?
      @takenPositions[x] = {}
    @takenPositions[x][y] = takenLevel

  markPositionFree: (x, y, takenLevel = 0) ->
    if @takenPositions[x]? && @takenPositions[x][y]?
      @takenPositions[x][y] = takenLevel

  ###
   * Returns if the player can build in this position or not
   * Team is there so that we can have team specific build zones, it can be null.
  ###
  isPositionTaken: (x, y, team, takenLevel = 0) ->
    if !ts.isServer && team != 1 && ts.game.settings.mode == config.modes.tutorial
      if !@tutorial.position?
        return true
      if @tutorial.position.x != x || @tutorial.position.y != y
        return true
    if x < 0 || y < 0
      return true
    if x >= @mapWidth || y >= @mapHeight
      return true
    if @buildRestrictions? && @buildRestrictions[team]?
      if @buildRestrictions[team].x?
        if x < @buildRestrictions[team].x.min || x > @buildRestrictions[team].x.max
          return true
      if @buildRestrictions[team].y?
        if y < @buildRestrictions[team].y.min || y > @buildRestrictions[team].y.max
          return true
    if !@takenPositions[x]? || !@takenPositions[x][y]?
      if takenLevel == 1
        return true
      else
        return false
    if @takenPositions[x][y] == takenLevel
      return false
    return true

  ###

   * Spawns a tower then returns the tick that it was spawned on
   *
  ###
  spawnTower: (xCoord, yCoord, towerType, ownerId) ->
    ts.log.debug("Spawning tower at x: " + xCoord + " y: " + yCoord)
    towerCreator = null
    towerCreatorTeam = null
    settings = ts.getConfig('towers', towerType);
    towerCreator = ts.game.playerManager.getPlayer(ownerId)
    towerCreatorTeam = towerCreator.getTeam();
    settings.owner = towerCreator
    takenLevel = 0
    if settings.buildsOnRoads
      takenLevel = 1
    if @isPositionTaken(xCoord, yCoord, towerCreatorTeam, takenLevel)
      ts.log.debug("Tower position is taken")
      return false
    @destroyTempTower(xCoord, yCoord)
    xPos = xCoord * config.tileSize
    yPos = yCoord * config.tileSize
    tower = ts.game.spawnEntity(GameEntity.CTYPE.TOWER, xPos, yPos, settings)
    @towers.push(tower)
    @quadTree.addEntity(tower)
    ts.game.dispatcher.emit gameMsg.createdTower, xCoord, yCoord, towerType, ownerId
    spawnTick = ts.getCurrentTick();
    return spawnTick;

  spawnTempTower: (xCoord, yCoord, towerType) ->
    settings = ts.getConfig('towers', towerType)
    tempTowerSettings = {}
    tempTowerProps = ['id', 'imageName', 'towerCost', 'cost', 'zIndex']
    for prop in tempTowerProps
      tempTowerSettings[prop] = settings[prop]
    xPos = xCoord * config.tileSize
    yPos = yCoord * config.tileSize
    tower = ts.game.spawnEntity(GameEntity.CTYPE.TEMPTOWER, xPos, yPos, tempTowerSettings)
    @tempTowers.push(tower)

  destroyTempTower: (xCoord, yCoord) ->
    xPos = xCoord * config.tileSize
    yPos = yCoord * config.tileSize
    for tower, idx in @tempTowers
      if tower.pos.x == xPos && tower.pos.y == yPos
        tower.kill()
        @tempTowers.splice(idx, 1)
        return true
    return false

  findTower: (xCoord, yCoord) ->
    xPos = xCoord * config.tileSize
    yPos = yCoord * config.tileSize
    for tower, idx in @towers
      if tower.pos.x == xPos && tower.pos.y == yPos
        return tower
    return null

  towerShoot: (towerId, minionId) ->
    for tower in @towers
      if tower.id == towerId
        tower.shoot minionId

  getTowersInArea: (xPos, yPos, rangeScaled) ->
    return @quadTree.getEntities(xPos, yPos, rangeScaled)


  getSnapshot: () ->
    snapshot =
      totalTowers: @towers.length
      towers: []
    for tower in @towers
      snapshot.towers.push tower.getSnapshot()
    return snapshot

module.exports = TowerManager
