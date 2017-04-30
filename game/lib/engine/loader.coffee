Image = require("./image.coffee")

class Loader
  resources: []
  gameClass: null
  status: 0
  done: false
  _unloaded: []
  _intervalId: 0
  _loadCallbackBound: null
  _loaded: 0
  assets: []
  percent: 0
  timeout: 200

  constructor: (gameClass, resources) ->
    @initPixi gameClass, resources
    return

  initPixi: (gameClass, resources) ->
    if @clearColor
      ts.system.stage.setBackgroundColor @clearColor.replace('#', '0x')
    @gameClass = gameClass
    i = 0
    while i < resources.length
      @assets.push resources[i].path
      i++
    @loader = new (PIXI.AssetLoader)(@assets)
    @loader.onProgress = @progress.bind(this)
    @loader.onComplete = @complete.bind(this)
    if @assets.length == 0
      @percent = 100
    @initStage()
    if @assets.length == 0
      @complete()
    return

  initStage: ->
    @bar = new (PIXI.Graphics)
    @bar.beginFill 0x333333
    @bar.drawRect 0, 0, ts.system.width, 20
    @bar.position.y = ts.system.height - 20
    @bar.scale.x = 0
    ts.system.stage.addChild @bar
    return

  progress: ->
    @_loaded++
    @percent = Math.round(@_loaded / @assets.length * 100)
    @onPercentChange()
    return

  onPercentChange: ->
    @bar.scale.x = @percent / 100
    return

  complete: ->
    setTimeout @end.bind(this), @timeout
    return

  load: ->
    @loader.load()
    @_intervalId = setInterval(@render.bind(this), @timeout)

  render: ->
    ts.system.renderer.render ts.system.stage

  loadResource: (res) ->
    res.load @_loadCallbackBound

  end: ->
    if @done
      return
    @done = true
    clearInterval @_intervalId
    ts.system.setGame @gameClass
    return

  _loadCallback: (path, status) ->
    if status
      @_unloaded.erase path
    else
      throw 'Failed to load resource: ' + path
    @status = 1 - (@_unloaded.length / @resources.length)
    if @_unloaded.length == 0
      # all done?
      setTimeout @end.bind(this), 250
    return

module.exports = Loader
