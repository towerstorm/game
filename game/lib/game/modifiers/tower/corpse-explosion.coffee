TowerModifier = require("../tower-modifier.coffee")
GameEntity = require("../../entities/game-entity.coffee")

gameMsg = require("config/game-messages")
vfxConfig = require("config/vfx")

_ = require("lodash")

class CorpseExplosionModifier extends TowerModifier
  name: "corpse-explosion"
  description: "Minion corpses explode dealing {{damagePercent}}% of the minions max health in damage in a {{explosionRadius}}m radius."
  damagePercent: 0    #Percent of minions life that should be dealt as damage
  explosionRadius: 0  #Radius of the explosion when a corpse explodes
  minionDiedHandle: null

  setup: (damagePercent, explosionRadius) ->
    super()
    @damagePercent = damagePercent
    @explosionRadius = explosionRadius
    @minionDiedHandle = ts.game.dispatcher.on gameMsg.minionDied, (minion, damageSource) =>
      @minionDied(minion, damageSource)

  minionDied: (minion, damageSource) ->
    if !@tower?
      return false
    if !@tower.canShoot()
      return false
    if !damageSource?
      return false
    if !minion? || !minion.pos? #Minion already got instantly eradicated... why?
      return false
    if !@tower.canAttackMinion(minion)
      return false
    dist = ts.game.functions.getDistSqrd(@tower.pos, minion.pos)
    if dist > @tower.rangeScaledSquared #Squared distance check is faster
      return false
    @explodeCorpse(minion)

  explodeCorpse: (deadMinion) ->
    if deadMinion.corpseExploded
      return false
    pos = _.clone(deadMinion.getCenter())
    @spawnExplosion(pos.x, pos.y)
    damage = deadMinion.maxHealth * (@damagePercent / 100)
    damageMethod = @tower.damageMethod
    attackMoveTypes = @tower.attackMoveTypes
    ts.game.minionManager.damageMinionsInArea(pos, @explosionRadius, damage, damageMethod, attackMoveTypes, @tower.owner.getTeam(), @)
    @tower.lastShot = ts.getCurrentTick()
    deadMinion.corpseExploded = true
    return true

  spawnExplosion: (x, y)->
    if ts.isHeadless
      return false
    item = vfxConfig.corpseExplosion
    ts.game.spawnEntity GameEntity.CTYPE.VFX, x, y, item

  checkTargetIsValid: (minion) ->
    if !minion?
      return false;
    if minion._killed
      return false
    if minion.health <= 0
      return false
    if @owner?
      if @owner.getTeam() == minion.team
        return false
    return true

  end: ->
    ts.game.dispatcher.off @minionDiedHandle
    @tower = null
    super()

  reset: ->
    super()
    @damagePercent = 0
    @explosionRadius = 0
    @minionDiedHandle = null
    @timer = 0
    @minion = null

module.exports = CorpseExplosionModifier
