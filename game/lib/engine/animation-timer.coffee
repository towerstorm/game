class AnimationTimer
  target: 0
  start: 0
  last: 0
  pauseTime: 0

  constructor: (seconds) ->
    @target = seconds or 0
    @start = AnimationTimer.time
    @last = AnimationTimer.time
    @pauseTime = 0
    return

  set: (seconds) ->
    @target = seconds or 0
    @start = AnimationTimer.time
    @pauseTime = 0
    return

  reset: ->
    @start = AnimationTimer.time
    @target = 0
    @pauseTime = 0
    return

  tick: ->
    delta = AnimationTimer.time - (@last)
    @last = AnimationTimer.time
    if @pauseTime then 0 else delta

  delta: ->
    (@pauseTime or AnimationTimer.time) - (@start) - (@target)

  pause: ->
    if !@pauseTime
      @pauseTime = AnimationTimer.time
    return

  unpause: ->
    if @pauseTime
      @start += AnimationTimer.time - (@pauseTime)
      @pauseTime = 0
    return

  @_last = 0
  @time = 0
  @timeScale = 1
  @maxStep = 0.05

  @step: ->
    current = Date.now()
    delta = (current - (AnimationTimer._last)) / 1000
    AnimationTimer.time += Math.min(delta, AnimationTimer.maxStep) * AnimationTimer.timeScale
    AnimationTimer._last = current
    return

module.exports = AnimationTimer
