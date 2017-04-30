AnimationTimer = require("./animation-timer.coffee")
Image = require("./image.coffee")

class Animation
  constructor: (sheet, frameTime, sequence, stop) ->
    @sheet = sheet
    @timer = new AnimationTimer()
    @sequence = sequence
    @pivot =
      x: sheet.width / 2
      y: sheet.height / 2
    @frame = 0
    @frameTime = frameTime
    @tile = 0
    @loopCount = 0
    @alpha = 1
    @angle = 0
    @finishedCallback = null
    @stop = !!stop
    if @sequence
      @tile = @sequence[0]
    return

  rewind: ->
    @timer.reset()
    @loopCount = 0
    @tile = @sequence[0]
    this

  gotoFrame: (f) ->
    @timer.set @frameTime * -f
    @update()
    return

  gotoRandomFrame: ->
    @gotoFrame Math.floor(Math.random() * @sequence.length)
    return

  isAnimFinished: ->
    @stop and @frame == @sequence.length - 1

  onFinished: (callback) ->
    @finishedCallback = callback
    return

  setPivot: (x, y) ->
    @sheet.setPivot x, y
    return

  update: ->
    frameTotal = Math.floor(@timer.delta() / @frameTime)
    @loopCount = Math.floor(frameTotal / @sequence.length)
    if @stop and @loopCount > 0
      @frame = @sequence.length - 1
      if @finishedCallback?
        @finishedCallback()
        @finishedCallback = null
    else
      @frame = frameTotal % @sequence.length
      if @sequence.length == 5
        #                  console.log("Time is ", this.timer.delta(), " frame is: ", this.frame);
      else
    @tile = @sequence[@frame]
    return

  draw: (targetX, targetY) ->
    if @sheet.movieClip
      @sheet.movieClip.visible = @sheet.visible
      if @sheet.pivot
        targetX += @sheet.pivot.x
        targetY += @sheet.pivot.y
      @sheet.movieClip.position.x = targetX
      @sheet.movieClip.position.y = targetY
      @sheet.movieClip.rotation = @angle
      @sheet.movieClip.gotoAndStop @tile
    return

  hide: ->
    if @sheet.movieClip
      @sheet.movieClip.visible = false
    return

module.exports = Animation
