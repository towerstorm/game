Modifier = require("./modifier.coffee")

class BulletModifier extends Modifier
  type: "bullet"
  timer: 0
  isActive: false
  minion: null

  setup: () ->

  reset: ->
    super()
    @timer = 0
    @isActive = false
    @minion = null

  end: ->
    @isActive = false
    super()

module.exports = BulletModifier
