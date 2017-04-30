### globals PIXI ###

AnimationTimer = require("./animation-timer.coffee")
Timer = require("./timer.coffee")

class System
  scale: 1
  tick: 0
  animationId: 0
  running: false
  delegate: null
  clock: null
  canvasId: null
  canvas: null
  context: null
  renderer: null
  transparent: true
  antialias: false

  constructor: (canvasId, fps, width, height, scale) ->
    @canvasId = canvasId
    @reset width, height, scale
    return

  initPixi: ->
    #Shit is broken here, make width and height * the pixiel ratio thingy so canvas  is proper size.
    @renderer = new (PIXI.autoDetectRenderer)(@width, @height,
      view: @canvas
      transparent: @transparent
      antialias: @antialias
      resolution: ts.ua.pixelRatio)
    @renderer.view.webkitImageSmoothingEnabled = false
    @view = @renderer.view
    @stage = new (PIXI.Stage)
    @container = new (PIXI.DisplayObjectContainer)
    @container.scale.x = @container.scale.y = @scale
    @stage.addChild @container
    #this.renderer.resize(this.realWidth, this.realHeight);
    return

  reset: (width, height, scale) ->
    @clock = new Timer()
    @canvas = ts.$(@canvasId)
    if @canvas
      @resize width, height, scale
    @initPixi()
    return

  resize: (width, height, scale) ->
    @width = width
    @height = height
    @realWidth = @width * @scale
    @realHeight = @height * @scale
    return

  setGame: (gameClass) ->
    ts.game = new gameClass
    ts.system.setDelegate ts.game
    return

  setDelegate: (object) ->
    @delegate = object
    @startRunLoop()
    return

  stopRunLoop: ->
    ts.clearAnimation @animationId
    @running = false
    return

  startRunLoop: ->
    @stopRunLoop()
    @animationId = ts.setAnimation(@run.bind(this), @canvas)
    @running = true
    return

  clear: (color) ->
    @context.fillStyle = color
    @context.fillRect 0, 0, @realWidth, @realHeight
    return

  calculateConstantTick: ->
    ticksPassed = @clock.constantTick() / Timer.constantStep
    ticksPassed = ticksPassed.round(5)
    @constantTick = if ticksPassed > 0 then Timer.constantStep else 0
    return

  run: ->
    Timer.step()
    AnimationTimer.step()
    @tick = @clock.tick()
    ticksPassed = @clock.constantTick() / Timer.constantStep
    ticksPassed = ticksPassed.round(5)
    @constantTick = if ticksPassed > 0 then Timer.constantStep else 0
    #We want the tick to always be the step rate if there were steps, 0 otherwise
    #We need to check if more than one tick has passed and if it has run a logic only update for each one that has passed (no drawing, else the game will choke and die, logic is fast drawing is slow)
    clockTotalTicks = parseInt(@clock.totalTicks, 10)
    #A Save of the current tick we are on so we can modify it in the next loop. It uses ParseInt so it doesn't bind it by reference
    if ticksPassed > 1
      while ticksPassed > 1
        #Countdown to just 1 tick remaining where update and drawing is done.
        ticksPassed--
        @clock.totalTicks = clockTotalTicks - ticksPassed
        #Hack the timer so that we play out each tick properly one at a time in order.
        # ts.log.info( "In system.run during loop setting clock.totalTicks to "+this.clock.totalTicks, " ticks passed is: ", ticksPassed, " clockTotalTicks is: ", clockTotalTicks);
        # console.log("In run, ticks passed: ", ticksPassed);
        success = @delegate.run(true)
        if !success
          return false
    @clock.totalTicks = clockTotalTicks
    # ts.log.info( "In system.run after loop setting clock.totalTicks to "+clockTotalTicks);
    #Do the normal run + draw after handling those extra ticks.
    # console.log("In run, ticks passed: ", ticksPassed);
    if @running
      @delegate.run()
    if ts.input
      ts.input.clearPressed()
    return

module.exports = System
