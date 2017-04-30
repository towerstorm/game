TowerAura = require("../tower-aura.coffee")

class DamageAura extends TowerAura
  name: "damage"
  description: "Increases nearby towers damage by {{damage}}%"
  damage: 0

  setup: (damage) ->
    @damage = damage
    super()

  reset: ->
    @damage = 0

  start: ->
    if !@target?
      return false
    super()
    @target.damageBoost += @damage
    @target.calculateDamage()

  end: ->
    @target.damageBoost -= @damage
    @target.calculateDamage()
    super()

module.exports = DamageAura
