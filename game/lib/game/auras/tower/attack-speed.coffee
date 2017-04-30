TowerAura = require("../tower-aura.coffee")

class AttackSpeedAura extends TowerAura
  name: "attack-speed"
  description: "Increases nearby towers attack speed by {{speedPercent}}%"
  speedPercent: 0

  constructor: ->

  setup: (speedPercent) ->
    @speedPercent = speedPercent
    super()

  reset: ->
    @speedPercent = 0

  start: ->
    if !@target?
      return false
    super()
    @target.attackSpeedBoost += @speedPercent;
    @target.calculateReloadTicks()

  end: ->
    @target.attackSpeedBoost -= @speedPercent;
    @target.calculateReloadTicks()
    super();

module.exports = AttackSpeedAura
