BulletModifier = require("../bullet-modifier.coffee")

class DetonationModifier extends BulletModifier
  name: "detonation"
  bullet: null

  reset: ->
    @bullet = null
    super()

  detonate: (bullet) ->
    @bullet = bullet
    @start();

  start: ->
    if !@bullet?
      return @end()
    super()

  end: ->
    @isActive = false
    @bullet = null
    super()
    return this

module.exports = DetonationModifier
