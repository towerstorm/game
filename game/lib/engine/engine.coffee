###global ts###

Input = require("./input.coffee")
Loader = require("./loader.coffee")
System = require("./system.coffee")
Timer = require("./timer.coffee")

_ = require("lodash")

Engine = (window) ->
  ts =
    game: null
    dispatcher: {}
    global: window
    resources: []
    ready: false
    ua: {}
    lib: ''
    logs: []
    isServer: false
    isHeadless: typeof document == 'undefined'
    _current: null
    _loadQueue: []
    _waitForOnload: 0
    $: (selector) ->
      if typeof document == 'undefined'
        return null
      if selector.charAt(0) == '#' then document.getElementById(selector.substr(1)) else document.getElementsByTagName(selector)
    isNumber: (n) ->
      !isNaN(parseFloat(n)) and isFinite(n)

    hashString: (str) ->
      hash = 0
      i = if str and typeof str == 'string' and str.length then str.length else 0
      while i--
        hash = (hash << 5) - hash + str.charCodeAt(i)
        hash = hash & hash
      hash

    addResource: (resource) ->
      ts.resources.push resource
      return

    addTick: ->
      if ts.system? and ts.system.clock?
        ts.system.clock.addTick()
      return

    setTick: (tick) ->
      if ts.system? and ts.system.clock?
        ts.system.clock.setTick tick
      return

    getCurrentTick: ->
      if ts.system? and ts.system.clock?
        return ts.system.clock.totalTicks
      return

    getCurrentConstantTime: ->
      ts.getCurrentTick() * Timer.constantStep

    getConfig: (name, itemName, ignoreCopy) ->
      if ignoreCopy
        return ts.game.config[name][itemName]
      if ts.game? and ts.game.config? and ts.game.config[name]?
        if itemName?
          return _.clone(ts.game.config[name][itemName])
        else
          return _.clone(ts.game.config[name])
      return null

    log:
      info: ->
      debug: ->
      all: ->
        @info.apply this, arguments
        @debug.apply this, arguments
        return

  vendors = [
    'ms'
    'moz'
    'webkit'
    'o'
  ]
  i = 0
  while i < vendors.length and !window.requestAnimationFrame
    window.requestAnimationFrame = window[vendors[i] + 'RequestAnimationFrame']
    i++
  # Use requestAnimationFrame if available
  if window.requestAnimationFrame
    next = 1
    anims = {}

    ts.setAnimation = (callback, element) ->
      current = next++
      anims[current] = true
      animate = ->
        if !anims[current]
          return
        # deleted?
        window.requestAnimationFrame animate, element
        callback()
        return

      window.requestAnimationFrame animate, element
      current
    ts.clearAnimation = (id) ->
      delete anims[id]
      return

  else
    ts.setAnimation = (callback, element) ->
      setInterval callback, 1000 / (ts.fps or 1000)
    ts.clearAnimation = (id) ->
      clearInterval id
      return

  ts.initClasses = ->
    ts.main = (canvasId, gameClass, fps, width, height, scale, loaderClass) ->
      ts.system = new System(canvasId, fps, width, height, scale or 1)
      if typeof document != 'undefined'
        ts.input = new Input()
      ts.ready = true
      loader = null
      if loaderClass
        loader = new loaderClass(gameClass, ts.resources)
      else
        loader = new Loader(gameClass, ts.resources)
      loader.load()
      return

    return
  return ts

module.exports = Engine
