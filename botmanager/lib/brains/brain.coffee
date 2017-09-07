config = require 'config/botmanager'
logic = require 'config/bot-logic'
bulkLoad = require("config/bulk-load")
towers = bulkLoad("towers");
minions = bulkLoad("minions");
maps = bulkLoad("maps");
gameMsg = require 'config/game-messages'
Dispatcher = require './../dispatcher'
TowerBrain = require './tower-brain'
MinionBrain = require './minion-brain'
_ = require 'lodash'
log = require('logger')

###*
* The brain of the bot keeps track of personality of the bot 
* and makes it's actions for it
###
class Brain
  game: null
  dispatcher: null
  attributes: {}
  towerBrain: null
  patientUntilTime: null  #Unix timestamp when this bot stops saving and starts building / upgrading again.
  patienceCount: 0       #How many times in a row we've been patient already
  totalTowerSpend: 0

  #Init does all the constructing so it can be unit tested
  constructor: (@game) ->
    #Initializing brain here because I don't know how to mock it properly yet as it's in a closure
    return @

  init: (attributes) ->
    @bindDispatcher(@game.dispatcher)
    log.info("Calling brain init with attributes: ", attributes)
    @attributes = attributes || logic.getRandomAttributes()
    @towerBrain = new TowerBrain(@game).init();
    return @

  bindDispatcher: (@dispatcher) ->
    @dispatcher.on config.messages.towerCreated, (xPos, yPos, ownerId, type) =>
      @towerCreated(ownerId, type)
    @dispatcher.on config.messages.gemDropped, (gem) =>
      @gemDropped(gem)

  #Just a wrapper so it can be mocked for testing
  randomRoll: ->
    return Math.random()

  shouldCollectGem: ->
    collectRoll = @randomRoll()
    if collectRoll < @attributes.gemCollectChance
      return true
    return false

  gemDropped: (gem) ->
    if !@shouldCollectGem()
      return false
    if !@game.getPlayer() || gem.playerId != @game.getPlayerId()
      return false
    @dispatcher.emit gameMsg.action.collectGem, gem.id

  towerCreated: (ownerId, type) ->
    if ownerId == @game.getPlayerId()
      towerDetails = towers[type]
      if towerDetails
        @totalTowerSpend += towerDetails.cost

  getChanceToBePatient: () ->
    return @attributes.patience * Math.pow(logic.patienceDecayRate, @patienceCount)

  isBeingPatient: () ->
    if Date.now() < @patientUntilTime
      return true
    shouldBePatient = @randomRoll() < @getChanceToBePatient()
    if shouldBePatient
      @patientUntilTime = Date.now() + logic.patienceTime * 1000
      @patienceCount++
      return true
    @patienceCount = 0
    return false

  getNextTurn: () ->
    turn = {}
    if @game.getGold() < 60 #Can't do anything if we have less than 50 gold.
      return turn
    if @isBeingPatient()
      return turn

    mapInfo = @game.getMapInfo();
    mapFlags = mapInfo.flags || {}
    canPlaceMinions = !mapFlags.cantPlaceMinions
    randRoll = @randomRoll()
    biasToBuildTowers = @getBiasToBuildTowers();
    randRoll += Math.min(logic.maxTowerBuildAggressionOffset, biasToBuildTowers); #more priority on building towers when we don't have enough and less when we do
    # log.info "Doing turn, Rand Roll: ", randRoll, " aggression: ", @attributes.aggression, " total tower spend: ", @towerBrain.totalTowerSpend, " biasToBuildTowers: ", biasToBuildTowers
    try
      if canPlaceMinions && (randRoll < @attributes.aggression)
          turn = {
            action: config.actions.placeMinion
            settings: @determineBestMinionToSend()
          }
      else
        if @randomRoll() < @attributes.upgradeTowerChance && @towerBrain.hasBuiltTowers()
          turn = {
            action: config.actions.upgradeTower
            settings: @towerBrain.determineBestTowerToUpgrade()
          }
        else
          towerSettings = @towerBrain.determineBestTowerToBuild();
          if !towerSettings?
            return turn
          turn = {
            action: config.actions.buildTower
            settings: towerSettings
          }
    catch e
      log.error("Trying to perform turn gave error: " + e)
      return {}
    return turn

  getBiasToBuildTowers: () ->
    biasToBuildTowers = 0
    totalMinutesPassed = Math.ceil(@game.getTimePassed() / (60 * 1000))
    minTargetSpend = @getMinTargetSpend(totalMinutesPassed)
    maxTargetSpend = @getMaxTargetSpend(totalMinutesPassed)
    if @totalTowerSpend < minTargetSpend
      biasToBuildTowers = (minTargetSpend - @totalTowerSpend) * logic.towerBiasPercentPerGold;
    else if @totalTowerSpend > maxTargetSpend
      biasToBuildTowers = (maxTargetSpend - @totalTowerSpend) * logic.towerBiasPercentPerGold;
#    log.info("TIME: ", totalMinutesPassed, " SPEND: ", @totalTowerSpend, " MINTS: ", minTargetSpend, ", MAXTS: ", maxTargetSpend, ", Bias: ", biasToBuildTowers)
    return biasToBuildTowers;

  getMinTargetSpend: (totalMinutesPassed) ->
    minTargetSpend = logic.startMinTargetTowerValue + (totalMinutesPassed * logic.minTargetTowerValuePerMin) + (totalMinutesPassed * logic.exponentialPercentageIncreaseInTargetsEachMinute)
    return minTargetSpend

  getMaxTargetSpend: (totalMinutesPassed) ->
    maxTargetSpend = logic.startMinTargetTowerValue + (totalMinutesPassed * logic.maxTargetTowerValuePerMin) + (totalMinutesPassed * logic.exponentialPercentageIncreaseInTargetsEachMinute)
    return maxTargetSpend

  ###
    Random for now, might have logic later on
  ###
  getSpawnPoint: () ->
    mapInfo = @game.getMapInfo();
    if !mapInfo
      throw new Error("getSpawnPoint could not find map of id: " + @game.getMapId())
    spawnPoint = _(mapInfo.spawnPoints).filter({team: @game.getTeam()}).sample()
    if !spawnPoint
      throw new Error("Could not find spawn point for team " + @game.getTeam())
    return spawnPoint

  ###
    More bias to send more expensive minions but sometimes throws in lower cost ones for fun
  ###
  determineBestMinionToSend: () ->
    # Get all minions we possibly can send then send random types with more
    # probability of sending them the more they cost
    minionsAvailable = []
    for type, minion of minions
      if @game.canSendMinion(type)
        minionsAvailable.push({type, cost: minion.cost})
    minionType = @getRandomMinionWeightedByGold(minionsAvailable)
    spawnPoint = @getSpawnPoint()
    return {x: spawnPoint.x, y: spawnPoint.y, type: minionType}

  getTotalCost: (minions) ->
    return minions.reduce(((prev, cur) -> prev + cur.cost), 0)

  getRandomMinionWeightedByGold: (minions) ->
    totalGoldCost = @getTotalCost(minions)
    randRoll = Math.floor(@randomRoll() * totalGoldCost)
    goldSum = 0
    for minion in minions
      goldSum += minion.cost
      if randRoll <= goldSum
        return minion.type
    return null


 

 



module.exports = Brain

