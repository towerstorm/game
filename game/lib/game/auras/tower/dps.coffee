TowerAura = require("../tower-aura.coffee")

class DpsAura extends TowerAura
  name: "dps"
  description: "Increases nearby towers damage per second by {{dps}}"
  dps: 0

  setup: (dps) ->
    @dps = dps
    super()

  reset: ->
    @dps = 0

  start: ->
    if !@target?
      return false
    super()
    @target.dpsBoost += @dps
    @target.calculateDamage()
    if !ts.isNumber(@target.damage)
      throw new Error("DPS Aura target damage is: " + @target.damage + " dpsBoost is: " + @dpsBoost + " dps is: " + @dps)

  end: ->
    @target.dpsBoost -= @dps
    @target.calculateDamage()
    if !ts.isNumber(@target.damage)
      throw new Error("DPS Aura target damage is: " + @target.damage + " dpsBoost is: " + @dpsBoost + " dps is: " + @dps)
    super()

module.exports = DpsAura
