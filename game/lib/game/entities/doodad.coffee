#global ts
###
A Doodad is a simple graphic that has no effect on the gameplay but has variable positioning (if it's always in the same place
it should go in the map itself). Stuff like arrows indicating where minions walk or overlay showing where you can't build are doodads.
###
GameEntity = require("./game-entity.coffee")

config = require("config/general")

class Doodad extends GameEntity
  ctype: GameEntity.CTYPE.DOODAD
  name: "doodad"

  constructor: (x, y, settings) ->
    @reset()
    super x, y, settings
    if settings?.imageName?
      @animSheet = ts.game.cache.getAnimationSheet(settings.imageName, @size.x, @size.y, config.doodads.zIndex);
      @addAnim("idle", 0.1, [0])

  reset: ->
    super();

  draw: ->
    super();

  update: ->
    super()

module.exports = Doodad
