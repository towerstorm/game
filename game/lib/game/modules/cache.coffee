AnimationSheet = require("../../engine/animation-sheet.coffee")
Image = require("../../engine/image.coffee")

config = require("config/general")

class Cache
  animationSheets: {}
  images: {}
  modifiers: {}

  constructor: ->
    @reset();

  reset: ->
    @animationSheets = {}
    @images = {}
    @modifiers = {}

  getAnimationSheet: (path, width, height, zIndex) ->
    if typeof document == "undefined"
      return null;
    return new AnimationSheet("/img/" + path, width, height, zIndex); #It's cached at the PIXI.js layer now, so each entity has its own AnimationSheet.
#        scale = scale || 1
#        if !@animationSheets[name]?
#          @animationSheets[name] = {}
#        if !@animationSheets[name][scale]
#          @animationSheets[name][scale] = new AnimationSheet(name, width, height)
#        return @animationSheets[name][scale]

  getImage: (name) ->
    if !@images[name]?
      @images[name] = new Image(name)
    return @images[name]

  getBulletModifier: (name, details) ->


module.exports = Cache
