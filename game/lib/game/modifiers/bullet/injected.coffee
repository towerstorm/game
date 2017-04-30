BulletModifier = require("../bullet-modifier.coffee")

class InjectedModifier extends BulletModifier
  name: "injected"
  description: "A base class for modifiers that inject into minions doing something to them."
  timer: 0
  duration: 0
  isActive: false
  minion: null

  setup: (duration) ->
    @duration = duration

  reset: ->
    super()
    @timer = 0
    @duration = 0
    @isActive = false
    @minion = null

  #Applies this modifier to the minion
  inject: (minion) ->
    @minion = minion
    @start();

  start: ->
    if !@minion?
      return @end()
    @isActive = true

  end: ->
    @isActive = false
    @minion = null
    super()
    return this

  update: (dt) ->
    @timer += dt
    @timer = @timer.round(5)
    if @timer >= @duration
      @end();
    return @isActive

module.exports = InjectedModifier
