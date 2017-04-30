Image = require("./image.coffee")

onLoadBindings = {}

onLoaded = (path) ->
  b = 0
  if !onLoadBindings[path] then return
  while b < onLoadBindings[path].length
    onLoadBindings[path][b]()
    b++
  delete onLoadBindings[path]
  return

class AnimationSheet
  constructor: (path, width, height, zIndex) ->
    this_ = this
    @tint = null
    @width = width
    @height = height
    @zIndex = zIndex
    @path = path
    @image = new Image(path)
    @image.parent = this
    @scale = 1
    @alpha = 1
    @visible = true
    @movieClip = null
    @destroyed = false
    @pivot = null

    imageLoaded = ->

      this_.image.data.onLoaded = ->
        this_.initMovieClip.call this_
        return

      this_.image.data.loadFramedSpriteSheet.call this_.image.data, width, height
      return

    if @image.loaded
      imageLoaded()
    else
      onLoadBindings[path] = onLoadBindings[path] or []
      onLoadBindings[path].push imageLoaded
      @image.loadCallback = onLoaded
    return

  setPivot: (x, y) ->
    @pivot =
      x: x
      y: y
    if @movieClip
      @movieClip.pivot = new (PIXI.Point)(x, y)
    return

  initMovieClip: ->
    if @destroyed
      #When resyncing the destroy is called before movieClip is loaded so don't load it if this animSheet should be destroyed.
      return false
    @movieClip = new (PIXI.MovieClip)(@image.data.frames)
    @movieClip.spawnTime = Date.now()
    @movieClip.visible = false
    if @pivot
      @movieClip.pivot = new (PIXI.Point)(@pivot.x, @pivot.y)
    if @tint
      @movieClip.tint = @tint
    @movieClip.scale = new (PIXI.Point)(@scale, @scale)
    @movieClip.width = @width
    @movieClip.height = @height
    @movieClip.zIndex = @zIndex
    @movieClip.alpha = @alpha
    ts.system.container.addChild @movieClip
    return

  setAlpha: (alpha) ->
    @alpha = alpha
    if @movieClip
      @movieClip.alpha = alpha
    return

  resize: (scale) ->
    @scale = scale
    if @movieClip
      @movieClip.scale = new (PIXI.Point)(@scale, @scale)
    return

  destroy: ->
    if @movieClip
      ts.system.container.removeChild @movieClip
      delete @movieClip
    @destroyed = true
    return

  setWidth: (width) ->
    @width = width
    if @movieClip?
      @movieClip.width = width
    return

  setHeight: (height) ->
    @height = height
    if @movieClip?
      @movieClip.height = height
    return

  setTint: (tint) ->
    @tint = tint
    if @movieClip?
      @movieClip.tint = tint
    return

  setVisible: (visible) ->
    @visible = visible
    if @movieClip?
      @movieClip.visible = visible
    return

module.exports = AnimationSheet
