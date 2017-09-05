#global ts
###
  TempGold / TempSouls - These are used to hide lag. They represent how many minions / souls the player has used that haven't yet been confirmed
  by the server. So when a player sends a minion it instantly subtracts the gold loally by adding the amount to tempSpend. Then when the server confirms
  the minion send it removes that gold from tempSpend and removes it from gold for real.
###

Timer = require("../../engine/timer.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")

class Player

  constructor: (id, settings) ->
    @reset()
    @id = id;
    @gold = settings.gold || 0
    @tempSpend = 0
    @income = (settings.income || 0) * ts.game.settings.incomeMultiplier;
    if ts.game.settings.linearGold
      @gold = 200
      @income = 1
    @lastIncomeTick = 0
    @health = settings.health || 0;
    @ping = 0
    @validMinionCache = {}
    @validTowerCache = {}
    @boosts = {}
    @name = "Unknown"
    #Soul refreshStartTick is set when a soul is sent and souls is < total
    #So that the refresh only starts after you've sent a minion rather than every 3 seconds always
    @souls = {
      total: settings.souls || 0
      tempTotal: 0
      max: settings.maxSouls || 20,
      refreshStartTick: 1
      refreshTime: 5
    }
    if ts.game.settings.linearGold
      @souls.max = 10
    @dispatcher = ts.game.dispatcher;
    @bindDispatcher();
    @playerUpdated();

  reset: ->
    @isMainPlayer = false
    @messages = []
    @gold = 0
    @tempSpend = 0
    @income = 0
    @lastIncomeTick = 0
    @health = 0
    @souls = {}
    @name = null
    @race = null
    @raceTowers = null
    @availableMinions = []
    @team = 0
    @ping = 0
    @validMinionCache = {}
    @validTowerCache = {}
    @boosts = {}
    @lastUpdate = 0
    @tutorial =
      enabled:
        minion: null
        tower: null
      visible:
        minion: []
        tower: []


  playerUpdated: (subType = "all") ->
    if !@isMainPlayer || ts.game.isFastForwarding || ts.game.largeTickQueue
      return false
    message = gameMsg.playerUpdated[subType]
    if !message
      return false
    @dispatcher.emit message, this

  getId: ->
    @id

  setName: (name) ->
    @name = name

  setRace: (race) ->
    if (!race) then console.trace("No race defined")
    if ts.getConfig('races', race)
      @race = ts.getConfig('races', race)
      
  getRace: ->
    @race

  setAvailableMinions: (minions) ->
    if !Array.isArray(minions) 
      return
    @availableMinions = minions
    
  getAvailableMinions: ->
    @availableMinions

  getTeamRaces: ->
    return ts.game.playerManager.getRacesOnTeam(ts.game.playerManager.getPlayers(), @getTeam())

  getTowers: ->
    if @raceTowers?
      return @raceTowers
    towers = ts.getConfig('towers')
    @raceTowers = []
    for name, tower of towers
      if tower.race == @race.name
        @raceTowers.push(tower)
    return @raceTowers

  setTeam: (team) ->
    @team = parseInt(team)

  getTeam: ->
    @team

  setPing: (ping) ->
    @ping = ping;

  getPing: ->
    return @ping

  getMinionHealth: (minionType) ->
    health = Math.round(ts.getConfig('minions', minionType, true).health)
    if @boosts.health
      health = (health * (1 + @boosts.health)).round(0)
    return Math.round(health)

  getMinionSpeed: (minionType) ->
    speed = ts.getConfig('minions', minionType).speed
    if @boosts.speed
      speed = (speed * (1 + @boosts.speed)).round(0)
    return speed

  getMinionCost: (minionType) ->
    cost = Math.round(ts.getConfig('minions', minionType, true).cost)
    return cost

  getMinionSoulCost: (minionType) ->
    return 1

  getMinionIncome: (minionType) ->
    income = (ts.getConfig('minions', minionType, true).income * ts.game.settings.incomeMultiplier).round(8)
    return income

  getMinionValue: (minionType) ->
    value = ts.getConfig('minions', minionType, true).value
    return value

  getIncome: ->
    @income

  addIncome: (amount) ->
    @income = Math.round((@income + amount) * 100) / 100;
    @playerUpdated('income');

  getGold: (ignoreTemp) ->
    totalGold = @gold
    if !ignoreTemp
      totalGold -= @tempSpend
    return totalGold

  addGold: (amount) ->
    @gold = Math.round((@gold + amount) * 100) / 100;
    ts.log.debug("Adding " + amount + " gold to " + @id + " total: " + @gold)
    @playerUpdated('gold');

  addTempSpend: (amount) ->
    @tempSpend = Math.round((@tempSpend + amount) * 100) / 100;
    @tempSpend = Math.max(@tempSpend, 0);
    @playerUpdated('gold')

  getHealth: ->
    return @health

  addHealth: (amount) ->
    @health = @health + amount
    @playerUpdated('health');

  getSouls: (ignoreTemp) ->
    totalSouls = @souls.total
    if !ignoreTemp
      totalSouls -= @souls.tempTotal

  addSouls: (amount) ->
    if (@souls.total + amount < 0) || (@souls.total + amount > @souls.max)
      return false
    @souls.total += amount
    @playerUpdated('souls')

  addTempSouls: (amount) ->
    @souls.tempTotal += amount
    @playerUpdated('souls')

  setIsMainPlayer: (isMainPlayer) ->
    @isMainPlayer = isMainPlayer
    @bindMainPlayerDispatcher();
    @playerUpdated();

  ###
  Makes this player recieve events from the global game dispatcher
  This is called for every player not just the main one, keep that in mind.
  ###
  bindDispatcher: ->
    @dispatcher.on gameMsg.createdMinion, (minion) =>
      @minionCreated(minion)
    @dispatcher.on gameMsg.minionDied, (minion, killer) =>
      @minionDied(minion, killer)
    @dispatcher.on gameMsg.castleDamage, (damage, castle) =>
      @castleDamaged(damage, castle)
    @dispatcher.on gameMsg.givePlayersGold, (amount) =>
      @addGold(amount)
    @dispatcher.on gameMsg.collectedGem, (playerId, minionType) =>
      if playerId == @getId()
        @collectGem(minionType)
    @dispatcher.on gameMsg.highlightButton, (type, subType) =>
      @highlightButton(type, subType)
    @dispatcher.on gameMsg.castleDecay, () =>
      @addHealth(-1)
    ts.game.dispatcher.on gameMsg.castleDied, (castle) =>
      @castleDied(castle)

  ###
  This is for events specific to the player playing, this is only run
  on the main player, not all.
  ###
  bindMainPlayerDispatcher: ->
    if !@isMainPlayer
      return false
    @dispatcher.on gameMsg.clickPlaceMinion, (x, y, minionNum) =>
      @placeMinion(x, y, minionNum)
    @dispatcher.on gameMsg.clickPlaceTower, (x, y, towerType) =>
      @placeTower(x, y, towerType)
    @dispatcher.on gameMsg.clickUpgradeTower, (tower) =>
      @upgradeTower(tower)
    @dispatcher.on gameMsg.clickSellTower, (tower) =>
      @sellTower(tower)
    return true

  minionCreated: (minion) ->
    if !minion.owner || minion.owner.getId() != @getId()
      return false
    minionType = minion.minionType
    @addGold(-@getMinionCost(minionType))
    @addSouls(-@getMinionSoulCost(minionType))
    if @souls.refreshStartTick == 0
      @souls.refreshStartTick = ts.getCurrentTick();
    return true

  minionDied: (minion, killer) ->
    if killer? && killer.owner?
      if (ts.game.settings.mode == config.modes.pvp && killer.owner.team == @team) || (ts.game.settings.mode == config.modes.survival && killer.owner.team == @team)
        totalGold = 0
        if killer.spawner?.bonusGold? #Spawner = The bullets tower
          totalGold += killer.spawner.bonusGold
        totalGold += @getMinionValue(minion.minionType)
        if killer.owner.getId() != @getId() #Ally killed this, not us
          totalGold /= 2                    #Half gold for allies.
        @addGold(totalGold)

  castleDamaged: (damage, castle) ->
    if castle.team? && castle.team == @team
      @addHealth(-damage)

  highlightButton: (type, subType) ->
    if @tutorial.enabled?
      @tutorial.enabled[type] = subType
    if @tutorial.visible? && @tutorial.visible[type]?
      @tutorial.visible[type].push(subType)
      @playerUpdated()

  canPickMinion: (minionType) ->
    if ts.game.isInPeaceTime()
      return false
    if !ts.isServer && ts.game.settings.mode == config.modes.tutorial && @tutorial.enabled.minion != minionType
      return false
    return true

  ###
    Ignore temp gold is for when comparing with gold after a message is recieved
    before the temporary minion is destroyed
  ###
  canSendMinion: (minionType, ignoreTemp) ->
    if ts.game.isInPeaceTime()
      return false
    if !@minionValidForPlayer(minionType)
      return false
    if !@canAffordMinion(minionType, ignoreTemp)
      return false
    if !@canAffordMinionSouls(minionType, ignoreTemp)
      return false
    return true

  minionValidForPlayer: (minionType) ->
    if ts.game.canBuildAnything()
      return true
    if @validMinionCache[minionType]?
      return @validMinionCache[minionType]
    minionDetails = ts.getConfig('minions', minionType)
    if !minionDetails?
      return @validMinionCache[minionType] = false
    if @getAvailableMinions().indexOf[minionType] == -1
      return @validMinionCache[minionType] = false
    return @validMinionCache[minionType] = true

  canAffordMinion: (minionType, ignoreTemp) ->
    gold = @getGold(ignoreTemp)
    if @getMinionCost(minionType) > gold
      return false
    return true

  canAffordMinionSouls: (minionType, ignoreTemp) ->
    souls = @getSouls(ignoreTemp)
    if @getMinionSoulCost(minionType) > souls
      return false
    return true

  canSeeMinionButton: (minionType) ->
    if ts.game.settings.mode.name == config.modes.tutorial && (minionType not in @tutorial.visible.minion)
      return false
    return true

  canPickTower: (towerType) ->
    if ts.game.settings.mode == config.modes.tutorial && @tutorial.enabled.tower != towerType
      return false
    if !@towerValidForPlayer(towerType)
      return false
    settings = ts.getConfig('towers', towerType, true)
    if settings.cost > @getGold()
      return false
    return true

  towerValidForPlayer: (towerType) ->
    if ts.game.canBuildAnything()
      return true
    if @validTowerCache[towerType]?
      return @validTowerCache[towerType]
    if towerType not in @getRace().towers
      return @validTowerCache[towerType] = false
    return @validTowerCache[towerType] = true

  canSeeTowerButton: (towerType) ->
    if ts.game.settings.mode.name == config.modes.tutorial && (towerType not in @tutorial.visible.tower)
      return false
    return true

  canPlaceTower: (towerType, ignoreTemp) ->
    if !@canAffordTower(towerType, ignoreTemp)
      return false
    return true

  canAffordTower: (towerType, ignoreTemp) ->
    gold = @getGold(ignoreTemp)
    if @getTowerCost(towerType) > gold
      return false
    return true

  getTowerCost: (towerType) ->
    settings = ts.getConfig('towers', towerType);
    return settings.cost

  canUpgradeTower: (towerType, currentLevel, ignoreTemp) ->
    settings = ts.getConfig('towers', towerType)
    nextLevel = currentLevel+1;
    if !settings? || !settings.levels[nextLevel]?
      return false
    gold = @getGold(ignoreTemp)
    if settings.levels[nextLevel].cost > gold
      return false
    return true

  placeTower: (x, y, towerType) ->
    if !@canPlaceTower(towerType)
      return false
    @dispatcher.emit(gameMsg.action.placeTower, x, y, towerType)
    return true

  upgradeTower: (tower) ->
    if !@canUpgradeTower(tower.towerType, tower.level)
      return false
    settings = ts.getConfig('towers', tower.towerType)
    tower.isUpgrading = true
    upgradeSettings = {xPos: tower.pos.x / config.tileSize, yPos: tower.pos.y / config.tileSize, ownerId: @getId()}
    @dispatcher.emit gameMsg.action.upgradeTower, upgradeSettings
    @addTempSpend(settings.levels[tower.level+1].cost)
    return true

  ###
  Called when a tower is upgraded to subtract gold and stuff
  ###
  towerUpgraded: (tower) ->
    settings = ts.getConfig('towers', tower.towerType);
    upgradeDetails = settings.levels[tower.level+1];
    @addGold(-upgradeDetails.cost)
    if @isMainPlayer
      @addTempSpend(-upgradeDetails.cost)
    return true

  sellTower: (tower) ->
    settings = ts.getConfig('towers', tower.towerType)
    saleSettings = {xPos: tower.pos.x / config.tileSize, yPos: tower.pos.y / config.tileSize, ownerId: @getId()}
    sellValue = tower.getSellValue()
    @dispatcher.emit gameMsg.action.sellTower, saleSettings
    return true

  towerSold: (tower) ->
    sellValue = tower.getSellValue()
    @addGold(sellValue)
    return true

  ###
  Called when a player clicks placeMinion, tells the server to send it. Temp gold
  cost is handled by the tempminion
  ###
  placeMinion: (x, y, minionType) ->
    if !@canSendMinion(minionType, false)
      return false
    @dispatcher.emit gameMsg.action.placeMinion, x, y, minionType
    return true

  updateMinionRespawns: ->
    refreshTimeInTicks = @souls.refreshTime / Timer.constantStep
    if @souls.refreshStartTick != 0 && @souls.total < @souls.max && (ts.getCurrentTick() >= @souls.refreshStartTick + refreshTimeInTicks)
      @addSouls(1)
      if @souls.total < @souls.max
        @souls.refreshStartTick = ts.getCurrentTick()
      else
        @souls.refreshStartTick = 0

  collectIncome: ->
    collectTimeInTicks = config.player.incomeCollectTime / Timer.constantStep
    if ts.getCurrentTick() == 0
      return false
    if @lastIncomeTick != 0 && ts.getCurrentTick() < (@lastIncomeTick + collectTimeInTicks)
      return false
    @addGold(@income);
    @lastIncomeTick = ts.getCurrentTick()

  collectGem: () ->
    if @souls.total < @souls.max
      @addSouls(1)
    if @souls.total == @souls.max
      @souls.refreshStartTick = 0

  castleDied: (castle) ->
    if castle.boosts?
      for name, amount of castle.boosts
        boostTeam = if castle.team == 0 then 1 else 0
        if @getTeam() == boostTeam
          if !@boosts[name]?
            @boosts[name] = 0
          @boosts[name] += amount
          @boosts[name] = @boosts[name].round(8)
          @playerUpdated('minions')

  update: ->
    @collectIncome()
    @updateMinionRespawns();
#        if @isMainPlayer
#          @playerUpdated();
    if @getHealth() <= 0
      return @dispatcher.emit gameMsg.playerDied, @

  getSnapshot: ->
    snapshot =
      id: @id
      health: @health
      gold: @gold
      income: @income
      souls: @souls.total
      team: @team
      race: @race.id

    return snapshot

module.exports = Player
