Doodad = require("./doodad.coffee")
Timer = require("../../engine/timer.coffee")

config = require("config/general")
minions = require("config/minions");
minionHelper = require("../helpers/minion.coffee");

cheapestMinionCost = minionHelper.getCostOfCheapestMinion(minions)
chanceToSkipSpawn = 80;

class SpawnPoint extends Doodad
  constructor: (x, y, settings) ->
    @reset()
    super(x, y, settings)
    @opacityChange = config.spawnPoints.opacityChange
    @minOpacity = config.spawnPoints.minOpacity
    @maxOpacity = config.spawnPoints.maxOpacity
    @configureAutospawner(settings.autospawn)
      

  reset: ->
    super()
    @opacityChange = 0
    @minOpacity = 0
    @maxOpacity = 0
    @spawnPointNum = 0
    @team = 0
    @gold = 0
    @income = 0
    @incomeGrowth = 0
    @incomeGrowthPercent = 0
    @lastIncomeTick = 0
    @healthBoost = 0
    @healthGrowth = 0
    @speedBoost = 0
    @speedGrowth = 0
    @lastBoostTick = 0
    
    
  configureAutospawner: (settings) ->
    if (!settings)
      return
    @healthGrowth = settings.healthGrowth or 0
    @speedGrowth = settings.speedGrowth or 0
    if (settings.value) 
      @gold = settings.value.gold or 0
      @income = settings.value.income or 0
      @incomeGrowth = settings.value.incomeGrowth or 0
      @incomeGrowthPercent = settings.value.incomeGrowthPercent or 0

  update: (tick) ->
    super()
    @updateGold()
    @increaseBoosts()
    @autoSpawnMinion(tick)
    
  draw: ->
    super()
    alpha = @animSheet.alpha
    alpha -= @opacityChange
    if alpha >= @maxOpacity || alpha <= @minOpacity
      @opacityChange = -@opacityChange
    if @animSheet
      @animSheet.setAlpha(alpha)
      
  updateGold: ->
    collectTimeInTicks = config.player.incomeCollectTime / Timer.constantStep
    if ts.getCurrentTick() == 0
      return 
    if @lastIncomeTick != 0 && ts.getCurrentTick() < (@lastIncomeTick + collectTimeInTicks)
      return 
    @increaseIncome()
    @collectIncome()
    @lastIncomeTick = ts.getCurrentTick()
    
  increaseIncome: ->
    if (@incomeGrowth)
      @income += @incomeGrowth
    if (@incomeGrowthPercent) 
      @income *= (1 + @incomeGrowthPercent)
      
  collectIncome: ->
    if (@income) 
      @gold += @income
      
  increaseBoosts: ->
    boostTimeInTicks = config.player.incomeCollectTime / Timer.constantStep
    if ts.getCurrentTick() == 0
      return 
    if @lastBoostTick != 0 && ts.getCurrentTick() < (@lastBoostTick + boostTimeInTicks)
      return 
    @increaseHealthBoost()
    @increaseSpeedBoost()
    @lastBoostTick = ts.getCurrentTick()
    
  increaseHealthBoost: ->
    if (@healthGrowth)
      @healthBoost += @healthGrowth
      
  increaseSpeedBoost: ->
    if (@speedGrowth)
      @speedBoost += @speedGrowth
      
  canSpawnMinion: ->
    if ts.game.isInPeaceTime()
      return false
    if @gold < cheapestMinionCost
      return false
    return true
      
  shouldSpawnMinion: (tick) ->
    oppositeTeam = Math.abs(@team - 1)
    if ts.game.playerManager.getTotalPlayersOnTeam(oppositeTeam) == 0
      return false
    if (((tick * ts.game.settings.seed * (@spawnPointNum + 1)) % 100) < chanceToSkipSpawn) 
      return false
    return true
      
  autoSpawnMinion: (tick) ->
    if !@shouldSpawnMinion(tick)
      return
    while @canSpawnMinion()
      minion = minionHelper.getRandomMinion(tick, ts.game.settings.seed * (@spawnPointNum + 1), minions, @gold)
      minion.healthMultiplier = 1 + @healthBoost
      minion.speedMultiplier = 1 + @speedBoost
      minion.nodePath = @spawnPointNum
      minion.team = @team
      ts.game.minionManager.spawnMinion(@pos.x / 48, @pos.y / 48, minion)
      @gold -= minion.cost
    
    

module.exports = SpawnPoint
