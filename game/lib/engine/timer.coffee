###global ts###

roundingPrecision = 8

class Timer
  target: 0
  timePausedFor: 0
  last: 0
  pauseTime: 0
  totalTicks: 0
  tickpauseTime: 0
  ticksPausedFor: 0
  timeAccelerating: false

  constructor: (seconds) ->
    @timePausedFor = 0
    @last = Timer.time
    @target = seconds or 0
    return

  set: (seconds) ->
    @target = seconds or 0
    @timePausedFor = 0
    @pauseTime = 0
    return

  reset: ->
    Timer.time = 0
    @timePausedFor = 0
    @totalTicks = 0
    @pauseTime = 0
    return

  tick: ->
    delta = Timer.time - (@last)
    @last = Timer.time
    if @pauseTime then 0 else delta

  accelerateTime: (accelerate) ->
    @timeAccelerating = accelerate
    return

  constantTick: (logData) ->
    if @pauseTime
      #don't increment when paused.
      return 0
    #When time is accelerated, minus one tick to this.timePausedFor (which will basically increase the game speed)
    if @timeAccelerating
      @timePausedFor -= Timer.constantStep
      @timePausedFor = @timePausedFor.round(roundingPrecision)
      #can't have negative time paused for.
      if @timePausedFor < 0
        @timePausedFor = 0
    delta = @timeSinceLastTick()
    ticksPassed = (delta - (delta % Timer.constantStep)) / Timer.constantStep
    #round down to the nearest multiple of constant step
    if typeof logData != 'undefined' and logData
      # console.log("Calling constantTick, ticks passed is: ", ticksPassed, " delta is: ", delta, " time is: ", Timer.time, " paused for is: ", this.timePausedFor, " total ticks: ", this.totalTicks);
    else
    @totalTicks += ticksPassed
    if typeof logData != 'undefined' and logData
      # ts.log.info( "In timer.constantTick setting this.totalTicks to "+this.totalTicks);
    else
    if @pauseTime then 0 else ticksPassed * Timer.constantStep

  addTick: ->
    Timer.time += Timer.constantStep
    Timer.time = Timer.time.round(roundingPrecision)
    return

  setTick: (tick) ->
    @totalTicks = tick
    Timer.time = tick * Timer.constantStep
    Timer.time = Timer.time.round(roundingPrecision)
    return

  timeSinceLastTick: ->
    timeSinceLastTick = (Timer.time - (@timePausedFor) - (@totalTicks * Timer.constantStep)).round(5)
    timeSinceLastTick

  delta: ->
    (@pauseTime or Timer.time) - (@timePausedFor) - (@target)

  pause: ->
    if !@pauseTime
      @pauseTime = Timer.time
      @tickpauseTime = @totalTicks
      # console.log("Pausing at time: ", this.pauseTime, "tick: ", this.tickpauseTime);
      ts.log.info 'Pausing at time: ', @pauseTime, 'tick: ', @tickpauseTime
    return

  unpause: ->
    if @pauseTime
      # var delta = Timer.time - (this.totalTicks * Timer.constantStep);
      # var ticksPassed = (delta - (delta % Timer.constantStep)) / Timer.constantStep; //round down to the nearest multiple of constant step
      # this.ticksPausedFor += ticksPassed;
      @timePausedFor += Timer.time - (@pauseTime)
      # console.log("Unpausing, time is: ", Timer.time, " paused at is: ", this.pauseTime, " time paused for is:", this.timePausedFor, " Current tick is: ", this.totalTicks);
      # console.log("Unpausing, time is: ", Timer.time, " paused at is: ", this.pauseTime, " time paused for is:", this.timePausedFor, " Current tick is: ", this.totalTicks);
      @last = Timer.time
      ts.system.constantTick = Timer.constantStep
      # Test Hack for now so taht items updating after the unpause run correctly.
      @pauseTime = 0
    return

  #Static Variables
  @_last: 0
  @time: 0
  @timeScale: 1
  @maxStep: 0.5

  #For Networking, velocity of minions is done off a constant tick rather than time passed so for each tick they always move the same amount
  #and things can be kept constant across all clients
  @constantStep: 0.1

  @step: ->
    current = Date.now()
    delta = (current - (Timer._last)) / 1000
    Timer.time += Math.min(delta, Timer.maxStep) * Timer.timeScale
    Timer._last = current
    return

module.exports = Timer
