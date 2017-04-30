###
  When a bullet has AOE it basically spawns a bullet for each enemy in range then scales the
  bullets damage based on distance from impact. The bullet also applies any other modifiers so
  a tower can have AOE freeze or AOE poison that travels to an area then explodes in AOE awesomeness.
###
DetonationModifier = require("./detonation.coffee")

class AoeModifier extends DetonationModifier
  name: "aoe"
  radius: 0
  baseDamagePercent: 0

  setup: (@radius, @baseDamagePercent = 100) ->
    super()

  reset: ->
    @radius = 0
    @baseDamagePercent = 0
    super()

  start: ->
    if !@bullet?
      return @end()
    super();
    @dealAoeDamage()
    @injectModifiers()
    @end()

  dealAoeDamage: ->
    damage = @bullet.damage * (@baseDamagePercent / 100)
    damageMethod = null
    attackMoveTypes = null
    if @bullet.spawner?
      damageMethod = @bullet.spawner.damageMethod
      attackMoveTypes = @bullet.spawner.attackMoveTypes
    ts.game.minionManager.damageMinionsInArea(@bullet.getDamageCenter(), @radius, damage, damageMethod, attackMoveTypes, @bullet.owner.getTeam(), @bullet)

  injectModifiers: ->
    if @bullet.modifiers? && @bullet.modifiers.length && @bullet.spawner
      center = @bullet.getDamageCenter()
      minions = ts.game.minionManager.getMinionsInArea(center.x, center.y, @radius)
      for minion in minions
        if @bullet.spawner? && @bullet.spawner.canAttackMinion(minion)
          minionModifiers = @bullet.spawner.getBulletModifiers() #Load new modifiers via the tower that fired this bullet.
          minion.injectModifiers(minionModifiers)

module.exports = AoeModifier
