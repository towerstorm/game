###
  ActionManager
  Manages all the commands players send to and from the server. So does all
  the tick processing and sending of new tick data to the server.
###

gameMsg = require("config/game-messages")
_ = require("lodash")

class TickManager
  isLogicPaused: false
  tickQueue: {}   #A Queue of things to do on each tick

  constructor: () ->
    @reset();

  reset: () ->
    @isLogicPaused = false
    @tickQueue = {}

  bindDispatcher: ->
    ts.game.dispatcher.on gameMsg.pauseLogic, =>
      @isLogicPaused = true
    ts.game.dispatcher.on gameMsg.unpauseLogic, =>
      @isLogicPaused = false

  pauseLogic: ->
    ts.game.dispatcher.emit gameMsg.pauseLogic

  unpauseLogic: ->
    ts.game.dispatcher.emit gameMsg.unpauseLogic

  addTick: (tickId, data) ->
    @tickQueue[tickId] = data

  removeTick: (tickId) ->
    delete @tickQueue[tickId]

  queueItem: (tickId, itemType, data) ->
    if !ts.isNumber(tickId)
      return false
#        console.log "Queueing tick item for tick ", tickId, " itemType: ", itemType, " data: ", data
    if !@tickQueue[tickId]?
      @tickQueue[tickId] = {}
    if !@tickQueue[tickId][itemType]?
      @tickQueue[tickId][itemType] = []
    @tickQueue[tickId][itemType].push data

  processTick: (tickId) ->
    if !ts.isServer
      if ts.game.logicPaused
        if @tickQueue[tickId]?
#              ts.log.info( "Have tick ", tickId, " unpausing") //DEVONLY
          @unpauseLogic();
      else
        if tickId > ts.game.lastTick #Don't do this stuff if we haven't advanced to a new tick yet.
          if !@tickQueue[tickId]?
#                ts.log.info( "Don't have tick ", tickId, " pausing") //DEVONLY
            @pauseLogic();
            return false;
    if tickId > ts.game.lastTick #Don't do this stuff if we haven't advanced to a new tick yet.
      ts.game.dispatcher.emit gameMsg.getPlayers, (players) =>
        if players?
          tickData = _.clone(@tickQueue[tickId])
          if !tickData? && ts.isServer then tickData = {}
          if tickData?
            if tickData.towers?
              @processTowers(tickData.towers, players)
            if tickData.towerUpgrades?
              @processTowerUpgrades(tickData.towerUpgrades, players)
            if tickData.towerSales?
              @processTowerSales(tickData.towerSales, players)
            if tickData.minions?
              @processMinions(tickData.minions, players)
            if tickData.pickups?
              @processPickups(tickData.pickups)

  processTowers: (towerData, players) ->
    for tower in towerData
      tower = _.clone(tower); #Need to create a copy of the settings so this tickQueue data isn't modified by the functions.
      ownerId = tower.ownerId
      if ownerId? && players[ownerId]?
        tower.owner = players[ownerId];
      if tower.owner.canPlaceTower(tower.towerType, true)
        didSpawn = ts.game.towerManager.spawnTower(tower.xPos, tower.yPos, tower.towerType, ownerId)
        if didSpawn && ownerId? && players[ownerId]?
          players[ownerId].addGold(-ts.getConfig('towers', tower.towerType).cost)
          ts.game.dispatcher.emit gameMsg.statAdd, ownerId, 'towersBuild', 1

  processTowerUpgrades: (towerUpgradeData, players) ->
    for towerUpgrade in towerUpgradeData
      owner = players[towerUpgrade.ownerId]
      tower = ts.game.towerManager.findTower(towerUpgrade.xPos, towerUpgrade.yPos)
      if owner? && tower? && owner.canUpgradeTower(tower.towerType, tower.level, true)
        didUpgrade = owner.towerUpgraded(tower)
        if didUpgrade
          tower.upgrade();

  processTowerSales: (towerSaleData, players) ->
    for towerSale in towerSaleData
      owner = players[towerSale.ownerId]
      tower = ts.game.towerManager.findTower(towerSale.xPos, towerSale.yPos)
      if owner? && tower?
        didSell = owner.towerSold(tower)
        if didSell
          tower.sell();

  processMinions: (minionData, players) ->
    for minion in minionData
      minion = _.clone(minion)
      if minion.ownerId == 0 # 0 = PvE spawn
        team = 1
      else
        owner = players[minion.ownerId]
        team = owner.getTeam()
        if !owner?
          ts.log.info("In Queue minion with an owner that doesn't exist")
      for spawnPoint, spNum in ts.game.map.spawnPoints
        if spawnPoint.x == minion.xPos && spawnPoint.y == minion.yPos && spawnPoint.team == team
          minion.spawnPoint = _.clone(spawnPoint)
          minion.nodePath = spNum
      if !minion.spawnPoint?
        console.error "Spawn point  at pos ", minion.xPos, ",", minion.yPos , " team: ", team, " not found"
      else
        spawnSettings = {
          minionType: minion.minionType
          nodePath: minion.nodePath
          team: team
          owner: owner
        }
        canSpawn = owner.canSendMinion(spawnSettings.minionType, true);
        if canSpawn
          ts.game.dispatcher.emit gameMsg.statAdd, minion.ownerId, 'minionsSent', 1
          minionId = ts.game.minionManager.spawnMinion(minion.spawnPoint.x, minion.spawnPoint.y, spawnSettings)

  processPickups: (pickupData) ->
    for pickup in pickupData
      if pickup.id?
        ts.game.gemManager.collectGem(pickup.id)

module.exports = TickManager
