Modifier = require("./modifier.coffee")

class TowerModifier extends Modifier
  type: "tower"
  tower: null

  setup: () ->

  inject: (tower) ->
    @tower = tower

  end: ->
    super()

  reset: ->
    super()
    @timer = 0
    @tower = null

module.exports = TowerModifier
