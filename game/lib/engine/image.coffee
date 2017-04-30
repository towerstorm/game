class Image

  staticInstantiate: (path) ->
    return Image.cache[path] or null

  constructor: (path) ->
    @reset()
    @path = path
    @load()
    return

  reset: ->
    @data = null
    @dataUnscaled = null
    @width = 0
    @height = 0
    @widthUnscaled = 0
    @heightUnscaled = 0
    @loaded = false
    @failed = false
    @loadCallback = null
    @path = ''
    @scale = 1
    @parent = null

  load: (loadCallback) ->
    if @loaded or typeof Image == 'undefined'
      if loadCallback
        loadCallback @path, true
      return
    else if !@loaded and ts.ready
      @loadCallback = loadCallback or null
      src = @path
      @data = new (PIXI.ImageLoader)(src)
      @data.onLoaded = @onload.bind(this)
      @data.onError = @onerror.bind(this)
      @data.load()
    else
      ts.addResource this
    Image.cache[@path] = this
    return

  reload: ->
    @loaded = false
    src = @path + '?' + Date.now()
    @data = new (PIXI.ImageLoader)(src)
    @data.onLoaded = @onload.bind(this)
    return

  onload: (event) ->
    @width = @data.width
    @widthUnscaled = @data.width
    @height = @data.height
    @heightUnscaled = @data.height
    @dataUnscaled = @data
    scale = ts.system.scale
    if @parent and @parent.scale? and @parent.scale != 1
      scale *= @parent.scale
    if scale != 1
      scale = Math.floor(scale * 100) / 100
      @resize scale
    @loaded = true
    if @loadCallback
      @loadCallback @path, true
    return

  onerror: (event) ->
    @failed = true
    ts.log.info 'Failed to load image, event is: ' + event + ' path is ' + @path
    if @loadCallback
      @loadCallback @path, false
    return

  resize: (scale) ->
    if typeof window == 'undefined'
      return false
    @scale = scale
    @data.scale = new (PIXI.Point)(2, 2)
    return

  draw: (targetX, targetY, sourceX, sourceY, width, height) ->
    if !@loaded
      return
    scale = ts.system.scale
    sourceX = if sourceX then sourceX * scale else 0
    sourceY = if sourceY then sourceY * scale else 0
    width = (if width then width else @width) * scale
    height = (if height then height else @height) * scale
    return

  @cache = {}

  @reloadCache: ->
    for path of Image.cache
      Image.cache[path].reload()
    return


module.exports = Image
