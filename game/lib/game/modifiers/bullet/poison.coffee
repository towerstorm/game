InjectedModifier = require("./injected.coffee")

class PoisonModifier extends InjectedModifier
  name: "poison"
  description: "Poisons enemies dealing {{damagePerSecond}} damage each second over {{duration}} seconds."
  damagePerSecond: 0
  owner: null
  setup: (duration, damagePerSecond) ->
    super(duration)
    @damagePerSecond = damagePerSecond

  reset: ->
    super()
    @damagePerSecond = 0
    @owner = null

  inject: (minion) ->
    super(minion)

  start: ->
    if !@minion?
      return @end()
    super();
    @owner = @minion.lastDamageSource

  end: ->
    super();

  update: (dt) ->
    #Adding the damage recieve before parent so it will deal damage on the last tick before parent ends this modifier
    if @isActive && (@timer + dt).round(5) % 1 == 0
      @minion.receiveDamage(@damagePerSecond, @owner)
    super(dt);

module.exports = PoisonModifier
