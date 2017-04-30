KEY = require ("./keys.coffee")

class Input
  constructor: ->
    @bindings = {}
    @actions = {}
    @presses = {}
    @locks = {}
    @delayedKeyup = {}
    @isUsingMouse = false
    @isUsingKeyboard = false
    @mouse =
      x: 0
      y: 0

  initMouse: ->
    if @isUsingMouse
      return
    @isUsingMouse = true
    mouseWheelBound = @mousewheel.bind(this)
    ts.system.canvas.addEventListener 'mousewheel', mouseWheelBound, false
    ts.system.canvas.addEventListener 'DOMMouseScroll', mouseWheelBound, false
    ts.system.canvas.addEventListener 'contextmenu', @contextmenu.bind(this), false
    ts.system.canvas.addEventListener 'mousedown', @keydown.bind(this), false
    ts.system.canvas.addEventListener 'mouseup', @keyup.bind(this), false
    ts.system.canvas.addEventListener 'mousemove', @mousemove.bind(this), false
    ts.system.canvas.addEventListener 'touchstart', @keydown.bind(this), false
    ts.system.canvas.addEventListener 'touchend', @keyup.bind(this), false
    ts.system.canvas.addEventListener 'touchmove', @mousemove.bind(this), false
    return

  initKeyboard: ->
    if @isUsingKeyboard
      return
    @isUsingKeyboard = true
    window.addEventListener 'keydown', @keydown.bind(this), false
    window.addEventListener 'keyup', @keyup.bind(this), false
    return

  mousewheel: (event) ->
    delta = if event.wheelDelta then event.wheelDelta else event.detail * -1
    code = if delta > 0 then KEY.MWHEEL_UP else KEY.MWHEEL_DOWN
    action = @bindings[code]
    if action
      @actions[action] = true
      @presses[action] = true
      @delayedKeyup[action] = true
      event.stopPropagation()
      event.preventDefault()
    return

  mousemove: (event) ->
    el = ts.system.canvas
    pos =
      left: 0
      top: 0
    while el?
      pos.left += el.offsetLeft
      pos.top += el.offsetTop
      el = el.offsetParent
    tx = event.pageX
    ty = event.pageY
    if event.touches
      tx = event.touches[0].clientX
      ty = event.touches[0].clientY
    @mouse.x = (tx - (pos.left)) / ts.system.scale * ts.ua.pixelRatio
    @mouse.y = (ty - (pos.top)) / ts.system.scale * ts.ua.pixelRatio
    return

  contextmenu: (event) ->
    if @bindings[KEY.MOUSE2]
      event.stopPropagation()
      event.preventDefault()
    return

  keydown: (event) ->
    if event.target.type == 'text'
      return
    code = if event.type == 'keydown' then event.keyCode else if event.button == 2 then KEY.MOUSE2 else KEY.MOUSE1
    if event.type == 'touchstart' or event.type == 'mousedown'
      @mousemove event
    action = @bindings[code]
    if action
      @actions[action] = true
      if !@locks[action]
        @presses[action] = true
        @locks[action] = true
    return

  keyup: (event) ->
    if event.target.type == 'text'
      return
    code = if event.type == 'keyup' then event.keyCode else if event.button == 2 then KEY.MOUSE2 else KEY.MOUSE1
    action = @bindings[code]
    if action
      @delayedKeyup[action] = true
      event.stopPropagation()
      event.preventDefault()
    return

  bind: (key, action) ->
    if key < 0
      @initMouse()
    else if key > 0
      @initKeyboard()
    @bindings[key] = action
    return

  bindTouch: (selector, action) ->
    element = ts.$(selector)
    that = this
    element.addEventListener 'touchstart', ((ev) ->
      that.touchStart ev, action
      return
    ), false
    element.addEventListener 'touchend', ((ev) ->
      that.touchEnd ev, action
      return
    ), false
    return

  unbind: (key) ->
    action = @bindings[key]
    @delayedKeyup[action] = true
    @bindings[key] = null
    return

  unbindAll: ->
    @bindings = {}
    @actions = {}
    @presses = {}
    @locks = {}
    @delayedKeyup = {}
    return

  state: (action) ->
    @actions[action]

  pressed: (action) ->
    @presses[action]

  released: (action) ->
    @delayedKeyup[action]

  clearPressed: ->
    for action of @delayedKeyup
      @actions[action] = false
      @locks[action] = false
    @delayedKeyup = {}
    @presses = {}
    return

  touchStart: (event, action) ->
    @actions[action] = true
    @presses[action] = true
    false

  touchEnd: (event, action) ->
    @delayedKeyup[action] = true
    false

module.exports = Input
