config = require 'config/botmanager'
logic = require 'config/bot-logic'
bulkLoad = require("config/bulk-load")
towers = bulkLoad("towers");
maps = bulkLoad("maps");
log = require 'logger'
assert = require("assert")
Dispatcher = require './../dispatcher'
_ = require 'lodash'

###
The tower brain analyses the map and figures out the best place to put towers
at any point in time. It can have a randomness attribute which makes it 
sometimes randomly pick the 2nd or nth best position instead so that bots
don't always play in the same way
###
class TowerBrain
  randomness: 0 
  totalTowerSpend: 0
  towerPositions: []
  takenPositions: {}
  cachedBuildPoints: {} #Array of [range] = buildPointsList
  myTowers: []
  dispatcher: null
  mapDetails: null

  constructor: (@game) ->
    @randomness = 20   #Picks from the top 20 positions each time
    @totalTowerSpend = 0
    @towerPositions = []
    @takenPositions = {}
    @cachedBuildPoints = {}
    @myTowers = []
    @dispatcher = null
    @mapDetails = null
    return @

  init: ->   
    @bindDispatcher(@game.dispatcher)
    return @

  initMap: (mapId) ->
    @mapDetails = @getMapDetails(mapId)
    mapWidthTiles = @mapDetails.width
    mapHeightTiles = @mapDetails.height
    @towerPositions = []
    for x in [0...mapWidthTiles]
      for y in [0...mapHeightTiles]
        @towerPositions.push({x: x, y: y})

  bindDispatcher: (@dispatcher) ->
    @dispatcher.on config.messages.gameBeginning, (details) =>
      @initMap(details.settings.mapId)
    @dispatcher.on config.messages.towerCreated, (xPos, yPos, ownerId) =>
      @markTowerPositionTaken(xPos, yPos)
      @towerCreated(xPos, yPos, ownerId)

  markTowerPositionTaken: (xPos, yPos) ->
    if !@takenPositions[xPos]?
      @takenPositions[xPos] = {}
    @takenPositions[xPos][yPos] = true

  towerCreated: (xPos, yPos, ownerId) ->
    if @game.getPlayer() && ownerId == @game.getPlayerId()
      @myTowers.push({xPos, yPos, ownerId})

  hasBuiltTowers: () ->
    return @myTowers.length

  isPositionTaken: (xCoord, yCoord) ->
    if !@takenPositions[xCoord]?
      return false
    if !@takenPositions[xCoord][yCoord]? || !@takenPositions[xCoord][yCoord]
      return false
    return true


  getMapDetails: (mapId) ->
    mapDetails = {width: 0, height: 0, nodePaths: []}
    log.info("Map details for map " + mapId + ": " + maps[mapId])
    assert(maps[mapId])
    map = maps[mapId]
    mapDetails.width = map.width
    mapDetails.height = map.height
    #Load the paths that we care about, only those that are owned by the opposing team
    if map.spawnPoints? && @game.getTeam()?
      for spawnPoint, num in map.spawnPoints
        if spawnPoint.team != @game.getTeam() 
          mapDetails.nodePaths.push(map.nodePaths[num]);
    return mapDetails

  determineBestTowerToUpgrade: () ->
    if !@myTowers.length
      return null
    return @myTowers[Math.floor(Math.random() * @myTowers.length)]

  determineBestTowerToBuild: () ->
    buildDetails = {
      type: "basic"
      x: 0
      y: 0
    }

    # Get all towers we possibly can send then send random types with more 
    # probability of sending them the more they cost
    towersAvailable = []
    costOfAllTowers = 0
    for type, tower of towers
      if @game.getPlayer() && @game.canPickTower(type)
        towersAvailable.push(tower)
        costOfAllTowers += tower.cost
    if !towersAvailable.length
      return null

    randRoll = Math.floor(Math.random() * costOfAllTowers);
    goldSum = 0
    for tower in towersAvailable
      goldSum += tower.cost
      if randRoll < goldSum
        towerSettings = _.clone(tower)
        break;

    buildDetails.type = towerSettings.id
    towerCost = towerSettings.cost
    @totalTowerSpend += towerCost

    # Figure out the best spot to place this tower type
    towerPos = @getBestTowerPosition(towerSettings)
    if !towerPos?
      return null
    
    buildDetails.x = towerPos.x
    buildDetails.y = towerPos.y

    return buildDetails

  #Get a roll biased towards the first numbers (for picking best tower spot, generally go for the top)
  #the first number has (max) chance of being chosen, second has (max-1) etc.
  getBiasedRoll: (max)  ->
    totalRoll = (max * (max + 1)) / 2
    biasedRoll = Math.floor(Math.random() * totalRoll)
    rollSum = 0
    for x in [0...max]
      rollSum += (max - x) # For max of 10 first rollSum is 10, next is 9, 8, 7 etc
      if biasedRoll <= rollSum
        return x
    return 0



  ###
  Finds the best position on the map for this tower type taking into account
  it's range and abilities.
  ###
  getBestTowerPosition: (towerDetails) ->
    buildPoints = null; buildPoint = null; checkCount = 0
    buildPoints = [].concat(@calculateBestBuildPoints(towerDetails, @towerPositions, @mapDetails.nodePaths))
    buildPointIncrease = Math.floor(@game.getTimePassed() / 15);  #1 more build point opens up every 15 seconds
    while checkCount < 100
      checkCount++
      if buildPoint?
        if !@isPositionTaken(buildPoint.x, buildPoint.y)
          break;
        else
          buildPoints.splice(randRoll, 1)
      randRoll = @getBiasedRoll(@randomness + buildPointIncrease);
      buildPoint = buildPoints[randRoll]
    return buildPoint

  ###
  Goes through every possibly position that the tower could be placed and
  orders them by how good of a position they are for this tower type.
  ###
  calculateBestBuildPoints: (towerDetails, buildPositions, roadNodes) ->
    towerRange = towerDetails.range
    if @cachedBuildPoints[towerRange]?
      return @cachedBuildPoints[towerRange]

    possibleBuildPoints = [[], [], [], [], []]  #2D Array of [roadsInRange][buildPoints] then these are flattened to be sorted without an expensive sort
    for buildPos in buildPositions
      buildPoint = @getBuildPoint(buildPos, towerRange, roadNodes)
      if buildPoint.shortest == 0 #Can't build on roads, if shortest is 0 it must be on a road. 
        continue
#      buildPoint = @adjustBuildPointDetailsForRange(buildPoint, towerRange)
      roadsInRange = buildPoint.totalIntersects
      if roadsInRange > 0
        possibleBuildPoints[roadsInRange].push(buildPoint)



    possibleBuildPointsFlat = []
    for num in [4...0] 
      possibleBuildPointsFlat = possibleBuildPointsFlat.concat(possibleBuildPoints[num])
    possibleBuildPointsFlat.sort((a, b) -> return b.weighting - a.weighting)

    @cachedBuildPoints[towerRange] = possibleBuildPointsFlat
    return @cachedBuildPoints[towerRange];

  getBuildWeighting: (totalIntersects, averageDist, closestToStart) ->
    return totalIntersects / (averageDist * ((closestToStart + 1) * 5))


  ###
  Returns an object of {distances: {north, south, east, west}, totalIntersects, shortest, average} for the distance to 
  all sides of the tower. Will be useful for figuring out the best spot to place towers :D

  It will use the north, south, east west to figure out how many sides of the tower will touch roads by comparing
  them to the towers shoot length and then towers will be placed where they can shoot the most roads and have shortest average distance
  ###
  getBuildPoint: (towerPos, towerRange, roads) ->
    closestToStart = 1000
    shortest = 1000
    average = null
    distances = {}
    distancesToStart = {}
    currentAverageTotal = 0
    totalIntersects = 0
    for road in roads
      for roadNode, num in road
        if road[num+1]?
          intersect = @checkTowerLineIntersectsPath towerPos, [roadNode, road[num+1]] 
          # log.info "Nodes: ", roadNode, " + ", road[num+1], " Got intersect of: ", intersect
          if intersect.direction? && intersect.distance <= towerRange && (!distances[intersect.direction]? || intersect.distance < distances[intersect.direction])
            distances[intersect.direction] = intersect.distance
            distancesToStart[intersect.direction] = num
            if intersect.distance < shortest
              shortest = intersect.distance
            if num < closestToStart
              closestToStart = num

    for own name, distance of distances
      if distance? 
        currentAverageTotal += distance
        totalIntersects += 1

    if totalIntersects > 0
      average = currentAverageTotal / totalIntersects

    returnData = 
      x: towerPos.x
      y: towerPos.y
      totalIntersects: totalIntersects
      shortest: shortest
      average: average
      distances: distances
      distancesToStart: distancesToStart
      closestToStart: closestToStart
      weighting: @getBuildWeighting(totalIntersects, average, closestToStart)

    return returnData

  ###
  towerPos = {x, y}
  path = [{x, y}, {x, y}]
  Only works for horizontal / vertical paths and towers atm as that's all that we're doing

  @returns {direction, distance}
  ###
  checkTowerLineIntersectsPath: (towerPos, path) ->
    direction = null
    if (path[0].y == path[1].y) && ((path[0].x <= towerPos.x && path[1].x >= towerPos.x) || (path[0].x >= towerPos.x && path[1].x <= towerPos.x)) #Intersects on the north or south
      if towerPos.y > path[0].y
        direction = 'north'
      else 
        direction = 'south'
      distance = Math.abs(towerPos.y - path[0].y)
    else if (path[0].x == path[1].x) && ((path[0].y <= towerPos.y && path[1].y >= towerPos.y) || (path[0].y >= towerPos.y && path[1].y <= towerPos.y)) #Intersects on the north or south
      if towerPos.x > path[0].x
        direction = 'west'
      else 
        direction = 'east'
      distance = Math.abs(towerPos.x - path[0].x)

    return {direction, distance};

module.exports = TowerBrain