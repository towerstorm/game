TowerAura = require("../tower-aura.coffee")

class GoldAura extends TowerAura
  name: "gold"
  description: "Every nearby tower recieves a bonus {{bonusGold}} gold per kill"
  bonusGold: 0

  setup: (bonusGold) ->
    @bonusGold = bonusGold
    super()

  reset: ->
    @bonusGold = 0

  start: ->
    if !@target?
      return false
    super()
    @target.bonusGold += @bonusGold

  end: ->
    @target.bonusGold -= @bonusGold
    super()

module.exports = GoldAura
