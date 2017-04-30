Dispatcher = require '../../../../lib/dispatcher'
config = require 'config/general'
assert = require 'assert'
proxyquire = require('proxyquire').noCallThru()

maps = {}
TowerBrain = proxyquire('../../../../lib/brains/tower-brain', {
    'config/maps': maps
});

describe "TowerBrain", ->
  towerBrain = null
  

  beforeEach ->
    towerBrain = new TowerBrain();

    towerBrain.game = 
      dispatcher: 
        on: -> assert true

  describe "constructor", ->

  describe "init", ->
    beforeEach ->
      towerBrain.bindDispatcher = -> assert true

  describe "initMap", ->
    beforeEach ->
      towerBrain.getMapDetails = -> assert true

    it "Should set mapdetails to return value of getMapDetails", ->
      expectedMapDetails = {test: "test"}      
      towerBrain.getMapDetails = ->
        return expectedMapDetails

      towerBrain.initMap();
      assert.equal towerBrain.mapDetails, expectedMapDetails

    it "Should create a tower position for every tile on the map", ->
      mapWidth = 60
      mapHeight = 30
      towerBrain.getMapDetails = ->
        return {width: mapWidth, height: mapHeight}

      expectedTotalPositions = mapWidth * mapHeight
      towerBrain.initMap();
      assert.equal towerBrain.towerPositions.length, expectedTotalPositions


  describe "bindDispatcher", ->
    dispatcher = null
    beforeEach ->
      towerBrain.towerCreated = -> true
      dispatcher = new Dispatcher();
      dispatcher.reset()

    it "Should bind towerCreated to markTowerPositionTaken", ->
      funcArgs = null
      towerBrain.markTowerPositionTaken = ->
        funcArgs = arguments
      towerBrain.bindDispatcher(dispatcher);
      dispatcher.emit config.messages.towerCreated, 10, 15
      assert funcArgs?
      assert.equal funcArgs[0], 10
      assert.equal funcArgs[1], 15

  describe "markTowerPositionTaken", ->
    beforeEach ->
      towerBrain.takenPositions = {}

    it "Should mark it as taken", ->
      towerBrain.markTowerPositionTaken 4, 7

      assert.equal towerBrain.takenPositions[0], null
      assert.equal towerBrain.takenPositions[4][0], null
      assert.equal towerBrain.takenPositions[4][7], true
      assert.equal towerBrain.takenPositions[4][8], null

  describe "towerCreated", ->
    beforeEach ->
      towerBrain.myTowers = []
      towerBrain.game =
        getPlayer: -> {}
        getPlayerId: -> 1

    it "Should add the tower to myTowers if the ownerId is us", ->
      towerBrain.towerCreated(2, 6, 1)
      assert.deepEqual towerBrain.myTowers, [{xPos: 2, yPos: 6, ownerId: 1}]

    it "Should not add the tower to myTowers if the ownerId is not us", ->
      towerBrain.towerCreated(2, 6, 2)
      assert.deepEqual towerBrain.myTowers, []





  describe "isPositionTaken", ->
    beforeEach ->
      towerBrain.takenPositions = {}

    it "Should return false when there are no positions taken", ->
      towerBrain.takenPositions = {}
      isTaken = towerBrain.isPositionTaken(5, 6)
      assert.equal isTaken, false

    it "Should return false when a tower in it's row is taken but not this position", ->
      towerBrain.takenPositions[4] = {'5': true}
      isTaken = towerBrain.isPositionTaken(4, 6)
      assert.equal isTaken, false

    it "Should return true when it's position is taken", ->
      towerBrain.takenPositions[6] = {'9': true}
      isTaken = towerBrain.isPositionTaken(6, 9);
      assert.equal isTaken, true

  describe "hasBuiltTowers", ->
    it "Should return false if myTowers is empty", ->
      towerBrain.myTowers = []
      assert.equal towerBrain.hasBuiltTowers(), false

    it "Should return true if myTowers has towers", ->
      towerBrain.myTowers = [{xPos: 3, yPos: 3, ownerId: 8}]
      assert.equal towerBrain.hasBuiltTowers(), true

  describe "getMapDetails", ->
    mapWidth = null
    mapHeight = null
    beforeEach ->
      mapWidth = 60
      mapHeight = 30
      maps = ["map1", "map2", {width: mapWidth, height: mapHeight, spawnPoints: null}]
      TowerBrain = proxyquire('../../../../lib/brains/tower-brain', {
        'config/maps': maps
      });
      towerBrain = new TowerBrain()

    it "Should return the maps width and height", ->
      mapDetails = towerBrain.getMapDetails(2);
      assert.equal mapDetails.width, mapWidth
      assert.equal mapDetails.height, mapHeight

    it "Should add a nodePath for every path that this player should build towers beside (opposite of its team)", ->
      botTeam = 1
      towerBrain.game =
        getTeam: ->
          return botTeam
      maps[2].spawnPoints = [
        {team: 0},
        {team: 0},
        {team: 1},
        {team: 0},
        {team: 1},
        {team: 1}
      ]
      maps[2].nodePaths = [
        {id: "nodePath1"},
        {id: "nodePath2"},
        {id: "nodePath3"},
        {id: "nodePath4"},
        {id: "nodePath5"},
        {id: "nodePath6"}
      ]
      mapDetails = towerBrain.getMapDetails(2);
      assert.equal mapDetails.nodePaths[0].id, "nodePath1"
      assert.equal mapDetails.nodePaths[1].id, "nodePath2"
      assert.equal mapDetails.nodePaths[2].id, "nodePath4"

  describe "determineBestTowerToUpgrade", ->
    it "Should go through the list of myTowers and return settings for one", ->
      towerBrain.myTowers = [
        {xPos: 3, yPos: 5, ownerId: 'xxx'}
        {xPos: 6, yPos: 7, ownerId: 'xxx'}
      ]
      pickedTower = towerBrain.determineBestTowerToUpgrade()
      assert pickedTower?, "Returned picked tower"
      assert pickedTower.xPos == 3 || pickedTower.xPos == 6, "Has xPos"
      assert pickedTower.yPos == 5 || pickedTower.yPos == 7, "Has yPos"
      assert.equal pickedTower.ownerId, 'xxx', "Has owner Id"

    it "Should return null if myTowers is empty", ->
      towerBrain.myTowers = []
      assert.equal towerBrain.determineBestTowerToUpgrade(), null


  describe "determineBestTowerToBuild", ->

  describe "getBestTowerPosition", ->
    beforeEach ->
      towerBrain.isPositionTaken = -> return false
      towerBrain.game = {getTimePassed: -> 5}

    it "Should return a buildPoint up to randomness", ->
      buildPoints = [{x: 5, y: 8}, {x: 9, y: 11}]

      towerBrain.calculateBestBuildPoints = ->
        return buildPoints
      towerBrain.randomness = 0 #so it always gets the first point
      towerBrain.mapDetails =
        nodePaths: null
      towerPos = towerBrain.getBestTowerPosition();
      assert.deepEqual towerPos, {x: 5, y: 8}

    it "Should delete a buildPoint from buildPoints (which is the cache) if it is taken and return another build point", ->
      buildPoints = [{x: 5, y: 8}, {x: 9, y: 11}, {x: 10, y: 15}]
      towerBrain.calculateBestBuildPoints = ->
        return buildPoints
      towerBrain.randomness = 0 #so it always gets the first point
      towerBrain.mapDetails =
        nodePaths: null
      towerBrain.isPositionTaken = (x, y) ->
        if x == 5 && y == 8
          return true
        return false

      towerPos = towerBrain.getBestTowerPosition();

      assert.deepEqual buildPoints, [{x: 9, y: 11}, {x: 10, y: 15}]
      assert.deepEqual towerPos, {x: 9, y: 11}

  describe "calculateBestBuildPoints", ->
    it "Should only return positions that are in range", ->
      towerDetails = {range: 3}
      towerPositions = [
        {x: 2, y: 19},  # 1 intersection
        {x: 28, y: 18}, # 2 intersections
        {x: 6, y: 2}    # 0 intersections
      ]
      roadNodes = [[{x: 0, y: 20}, {x: 30, y: 20}, {x: 30, y: 10}]]

      buildPoints = towerBrain.calculateBestBuildPoints(towerDetails, towerPositions, roadNodes)
      
      assert.equal buildPoints.length, 2

    it "Should be sorted by weightings", ->

    it "Should return a cached list of towers in range if it exists", ->
      towerBrain.cachedBuildPoints[3] = [{x: 5, y: 8}, {x: 9, y: 17}]
      towerDetails = {range: 3}
      buildPoints = towerBrain.calculateBestBuildPoints(towerDetails, null, null)
      assert.equal buildPoints, towerBrain.cachedBuildPoints[3];

    it "Should cache the build points it found at the end", ->
      towerDetails = {range: 8}
      towerPositions = [
        {x: 28, y: 18},
        {x: 28, y: 19},
        {x: 28, y: 17},
      ]
      roadNodes = [[{x: 0, y: 20}, {x: 30, y: 20}, {x: 30, y: 10}]]
      buildPoints = towerBrain.calculateBestBuildPoints(towerDetails, towerPositions, roadNodes)
      assert.deepEqual towerBrain.cachedBuildPoints[8], buildPoints


  describe "getBuildPoint", ->
    it "Should return the correct distance for a road below the tower", ->
      towerPos = {x: 10, y: 10}
      roadNodes = [[{x: 0, y: 20}, {x: 30, y: 20}]]

      distanceToRoads = towerBrain.getBuildPoint(towerPos, 100, roadNodes)
      assert.equal distanceToRoads.shortest, 10
      assert.equal distanceToRoads.average, 10
      assert.deepEqual distanceToRoads.distances, {'south': 10}

    it "Should get a good average distance and 2 intersects for a tower in a corner", ->
      towerPos = {x: 10, y: 10}
      roadNodes = [[{x: 0, y: 20}, {x: 30, y: 20}, {x: 30, y: 5}]]

      distanceToRoads = towerBrain.getBuildPoint(towerPos, 100, roadNodes)
      assert.equal distanceToRoads.shortest, 10
      assert.equal distanceToRoads.average, 15
      assert.deepEqual distanceToRoads.distances, {'south': 10, 'east': 20}      
      assert.equal distanceToRoads.totalIntersects, 2

    it "Should get a good average distance and 2 intersects for two seperate paths intersecting around the tower", ->
      towerPos = {x: 10, y: 10}
      roadNodes = [[{x: 0, y: 20}, {x: 30, y: 20}], [{x: 30, y: 20}, {x: 30, y: 5}]]

      distanceToRoads = towerBrain.getBuildPoint(towerPos, 100, roadNodes)
      assert.equal distanceToRoads.shortest, 10
      assert.equal distanceToRoads.average, 15
      assert.deepEqual distanceToRoads.distances, {'south': 10, 'east': 20}      
      assert.equal distanceToRoads.totalIntersects, 2

    it "Should set the closest variable to the roadNode it intersects with that is closest to the start", ->
      towerPos = {x: 10, y: 10}
      roadNodes = [[{x: 0, y: 20}, {x: 30, y: 20}, {x: 30, y: 5}]]
      distanceToRoads = towerBrain.getBuildPoint(towerPos, 100, roadNodes)
      assert.equal distanceToRoads.closestToStart, 0

  describe "checkTowerLineIntersectsPath", ->
    it "Should intersect on the south side", ->
      towerPos = {x: 10, y: 5}
      pathNodes = [{x: 0, y: 20}, {x: 30, y: 20}]

      intersect = towerBrain.checkTowerLineIntersectsPath towerPos, pathNodes
      assert.equal intersect.direction, "south"
      assert.equal intersect.distance, 15

    it "Should intersect on the north side", ->
      towerPos = {x: 10, y: 77}
      pathNodes = [{x: 0, y: 20}, {x: 30, y: 20}]

      intersect = towerBrain.checkTowerLineIntersectsPath towerPos, pathNodes
      assert.equal intersect.direction, "north"
      assert.equal intersect.distance, 57

    it "Should intersect on the east side", ->
      towerPos = {x: 27, y: 15}
      pathNodes = [{x: 30, y: 10}, {x: 30, y: 20}]

      intersect = towerBrain.checkTowerLineIntersectsPath towerPos, pathNodes
      assert.equal intersect.direction, "east"
      assert.equal intersect.distance, 3

    it "Should intersect on the west side", ->
      towerPos = {x: 99, y: 15}
      pathNodes = [{x: 30, y: 10}, {x: 30, y: 20}]

      intersect = towerBrain.checkTowerLineIntersectsPath towerPos, pathNodes
      assert.equal intersect.direction, "west"
      assert.equal intersect.distance, 69


