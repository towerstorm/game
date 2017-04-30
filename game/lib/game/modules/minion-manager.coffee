#global ts

Entity = require("../../engine/entity.coffee")
GameEntity = require("../entities/game-entity.coffee")
TempMinion = require("../entities/temp-minion.coffee")
Doodad = require("../entities/doodad.coffee")
QuadTree = require("./quad-tree.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")
mapConfig = require("../../../../config/maps")
minionConfig = require("config/minions")

_ = require("lodash")

class MinionManager
  scale: 0
  minions: []
  tempMinions: []
  spawnPoints: []
  mapNodes: []
  minionQueue: {} #A map for minion spawning holding each tick a minion needs to spawn like {100: [minion1, minion2], 200: [minion3]}
  totalQueuedMinions: 0
  totalAliveMinions: 0
  totalMinions: 0
  quadTree: null

  constructor: () ->
    @scale = config.tileSize
    @minions = []
    @quadTree = new QuadTree(@scale);

  reset: ->
    @scale = 0
    @minions = []
    @tempMinions = []
    @spawnPoints = []
    @mapNodes = []
    @minionQueue = {} #A map for minion spawning holding each tick a minion needs to spawn like {100 = [minion1, minion2], 200 = [minion3]}
    @totalQueuedMinions = 0
    @totalAliveMinions = 0
    @totalMinions = 0
    @quadTree = null

  begin: (mapId) ->
    map = _.cloneDeep(mapConfig[mapId]);
    @spawnPoints = map.spawnPoints;
    @mapNodes = map.nodePaths
    @bindDispatcher();

  scaleCoordinate: (value) ->
    return value * @scale

  drawHelperArrows: (playerTeam) ->
    for path, pathNum in @mapNodes
      team = @spawnPoints[pathNum].team
      for node, num in path
        if path[num+1]?
          @drawHelperArrow node.x, node.y, path[num+1].x, path[num+1].y, team == playerTeam
    return true;

  drawHelperArrow: (x, y, nextX, nextY, isFriendly) ->
    x = @scaleCoordinate(x); y = @scaleCoordinate(y); nextX = @scaleCoordinate(nextX); nextY = @scaleCoordinate(nextY);
    doodadType = if isFriendly then 'greenArrow' else 'redArrow'
    angle = ts.game.functions.calcAngleInRadians({x: x, y: y}, {x: nextX, y: nextY});
    ts.game.spawnEntity GameEntity.CTYPE.DOODAD, x, y, {doodadType: doodadType, angle: angle}
    return true;

  bindDispatcher: ->
    ts.game.dispatcher.on gameMsg.minionDied, (minion, killer) =>
      @minionDied(minion, killer)
    ts.game.dispatcher.on gameMsg.action.placeMinion, (x, y, minionType) =>
      @spawnTempMinion(x, y, minionType)
    ts.game.dispatcher.on gameMsg.tempMinionSuicide, (minionType) =>
      @destroyTempMinion(minionType)
    ts.game.dispatcher.on gameMsg.spawnMinion, (x, y, minionType) =>
      @spawnMinion(x, y, minionType)

  update: ->
    ts.log.debug("In minionManager update")
    currentTick = ts.getCurrentTick();
    if @minionQueue[currentTick]?
      for minion in @minionQueue[currentTick]
        @spawnMinion minion.xPos, minion.yPos, minion.settings
      delete @minionQueue[currentTick]
    @updateQuadTree();

  minionDied: (minion, killer) ->
    @totalAliveMinions--
    @minions.erase minion

  updateQuadTree: ->
    if @quadTree
      @quadTree.buildTree(@minions)

  getMinionsInArea: (xPos, yPos, range, sortByDistance = false) ->
    rangeScaled = range * config.tileSize + config.minions.width; # +64 for minion width as we want to add that on so towers shoot further.
    rangeSqrd = rangeScaled * rangeScaled
    minions = @quadTree.getEntities(xPos, yPos, rangeScaled)
    filteredMinions = []
    for minion in minions
      if ts.game.functions.getDistSqrd({x: xPos, y: yPos}, minion.getCenter()) <= (rangeSqrd + ((minion.width * minion.width) + (minion.height * minion.height))) #Add minion diameter so tower shoots minions even on their corner
        filteredMinions.push(minion)
    if sortByDistance
      filteredMinions.sort((a, b) -> return b.distanceTravelled - a.distanceTravelled )
    return filteredMinions

  damageMinionsInArea: (center, range, damage, damageMethod, attackMoveTypes, team, attacker) ->
    ts.log.debug("Damaging minions in area with center: ", center, " range ", range, " damage ", damage, " damageMethod ", damageMethod, " attackMoveTypes ", attackMoveTypes)
    rangeScaled = range * @scale
    rangeSqrd = rangeScaled * rangeScaled
    success = false
    ts.game.hud.addDebugCircle(center, rangeScaled)
    minions = @getMinionsInArea(center.x, center.y, range)
    for minion in minions
      if @checkTargetIsValid(minion, team, attackMoveTypes) && @checkTargetIsInRange(minion.getCenter(), center, rangeSqrd)
        success = true
        if damageMethod && damageMethod == "percent"
          minion.receiveDamage((damage / 100) * minion.maxHealth, attacker)
        else
          minion.receiveDamage(damage, attacker)
    return success

  damageMinionsInBox: (startX, startY, width, height, damage, damageMethod, attackMoveTypes, attackerTeam, attacker) ->
    ts.log.debug("Damaging minions in box with start ", startX, ", ", startY, " size ", width, " x ", height, " damage ", damage, " damageMethod ", damageMethod, " attackMoveTypes ", attackMoveTypes, " attackerTeam ", attackerTeam)
    success = false
    ts.game.hud.addDebugSquare(startX, startY, width, height)
    center = {x: startX + (width / 2), y: startY + (height / 2)}
    longestDistance = ts.game.functions.getDist(center, {x: startX, y: startY})
    range = (longestDistance / config.tileSize).round(8)
    minions = @getMinionsInArea(center.x, center.y, range)
    for minion in minions
      if @checkTargetIsValid(minion, attackerTeam, attackMoveTypes) && @checkTargetIsInBox(minion.getCenter(), startX, startY, width, height)
        success = true
        if damageMethod && damageMethod == "percent"
          minion.receiveDamage((damage / 100) * minion.maxHealth, attacker)
        else
          minion.receiveDamage(damage, attacker)
    return success

  checkTargetIsValid: (minion, attackerTeam, attackMoveTypes)->
    if !minion?
      return false;
    if !minion.canBeShot()
      return false
    if attackerTeam == minion.team && !ts.game.canAttackOwnMinions()
      return false
    if attackMoveTypes? && minion.moveType not in attackMoveTypes
      return false
    return true

  checkTargetIsInRange: (minionCenter, attackerCenter, attackerRangeSqrd) ->
    dist = ts.game.functions.getDistSqrd(attackerCenter, minionCenter)
    if dist > attackerRangeSqrd #Squared distance check is faster
      return false
    return true

  checkTargetIsInBox: (minionCenter, x, y, w, h) ->
    return ts.game.functions.pointInsideBox(minionCenter, {x, y, w, h})

  getNode: (path, nodeId) ->
    #If no path passed make it 0 by default
    if arguments.length == 1
      nodeId = arguments[0]; path = 0;
    if !@mapNodes || !@mapNodes[path]? || !@mapNodes[path][nodeId]?
      return null
    return _.clone @mapNodes[path][nodeId]

  getNodeScaled: (path, nodeId) ->
    node = @getNode(path, nodeId)
    if !node?
      return null
    node.x = @scaleCoordinate(node.x);
    node.y = @scaleCoordinate(node.y);
    return node;

  getNextMinionId: ->
    return @totalMinions++

  initTempMinionSettings: (minionType, owner) ->
    #We only want to use the minimum required setting, don't add all of them to the object
    allSettings = minionConfig[minionType]
    settings = {
      owner: owner
      cost: owner.getMinionCost(minionType)
      souls: owner.getMinionSoulCost(minionType)
      width: allSettings.width
      height: allSettings.height
      race: allSettings.race
      speed: allSettings.speed
      animations: allSettings.animations
      frames: allSettings.frames
      minionType: allSettings.minionType
      moveType: allSettings.moveType
      imageName: allSettings.imageName
    }
    return settings

  spawnTempMinion: (x, y, minionType, owner) ->
    mainPlayer = null
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      mainPlayer = player
    if !mainPlayer?
      return false
    owner = owner || mainPlayer
    team = owner.getTeam()
    xPos = @scaleCoordinate(x)
    yPos = @scaleCoordinate(y)
    settings = @initTempMinionSettings(minionType, owner)
    minion = ts.game.spawnEntity(GameEntity.CTYPE.TEMPMINION, xPos, yPos, settings)
    @tempMinions.push minion
    owner.addTempSpend(minion.cost)
    owner.addTempSouls(minion.souls)

  initMinionSettings: (settings) ->
    id = @getNextMinionId();
    settings ?= {}
    settings.name = "minion." + id
    if settings.owner?
      settings.health = settings.owner.getMinionHealth(settings.minionType)
      settings.speed = settings.owner.getMinionSpeed(settings.minionType)
      settings.souls = settings.owner.getMinionSoulCost(settings.minionType)
    settings = @applyMinionStatModifiers(settings)
    return settings
    
  applyMinionStatModifiers: (settings) ->
    healthMultiplier = settings.healthMultiplier or 1;
    speedMultiplier = settings.speedMultiplier or 1;
    settings.health = Math.floor(settings.health * healthMultiplier)
    settings.speed = Math.floor(settings.speed * speedMultiplier)
    delete settings.healthMultiplier
    delete settings.speedMultiplier
    return settings;
    

  spawnMinion: (x, y, settings) ->
    settings = _.extend(settings, minionConfig[settings.minionType])
    settings = @initMinionSettings(settings)
    mainPlayer = null
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      mainPlayer = player
    if settings.owner? && mainPlayer? && settings.owner.getId() == mainPlayer.getId()
      @destroyTempMinion(settings.minionType)
    if settings.owner?.income?
      minionIncome = settings.owner.getMinionIncome(settings.minionType)
      settings.owner.addIncome(minionIncome)
    xPos = @scaleCoordinate(x)
    yPos = @scaleCoordinate(y)
    ts.log.debug("Spawning minion at x: " + xPos + " y: " + yPos)
    minion = ts.game.spawnEntity(GameEntity.CTYPE.MINION, xPos, yPos, settings)
    @minions.push(minion)
    ts.game.dispatcher.emit(gameMsg.createdMinion, minion)
    @totalAliveMinions++
    @totalQueuedMinions--
    return settings.id;

  destroyTempMinion: (minionType) ->
    for minion, idx in @tempMinions
      if minion.minionType == minionType
        minion.owner.addTempSpend(-minion.cost)
        minion.owner.addTempSouls(-minion.souls);
        minion.kill();
        @tempMinions.splice(idx, 1)
        return true
    return false

  isValidSpawnPoint: (x, y, team) ->
    for spawnPoint in @spawnPoints
      if spawnPoint.x == x && spawnPoint.y == y && spawnPoint.team == team
        return true
    return false




  ###
   * Gets all the minions with positions as JSON
  ###
  getSnapshot: ->
    snapshot =
      totalMinions: @minions.length
      minions: []
    for minion in @minions
      snapshot.minions.push(minion.getSnapshot())
    snapshot

module.exports = MinionManager
