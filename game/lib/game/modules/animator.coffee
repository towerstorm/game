###
  An animator is created for any non frame animations that any entities have.
  So it does things like resizing, moving and changing opacity of the entity it's attached to
###

_ = require("lodash")

class Animator
  entity: null
  onFinishedCallback: null

  ### Settings ###
  delay: 0
  time: 0
  dontStartImmediately: false
  type: null
  startTime: null
  startWidth: null
  endWidth: null
  startHeight: null
  endHeight: null
  startColor: null
  endColor: null

  ### Original Entity Settings ###
  origSet: false
  origWidth: null
  origHeight: null
  origPos: null

  constructor: (entity, settings) ->
    _.extend(this, settings);
    @entity = entity;
    if !@dontStartImmediately
      @start()

  getTotalTime: ->
    return (@delay + @time).round(8)

  start: ->
    @startTime = Date.now()

  storeEntitySettings: () ->
    if @origSet then return false
    @origWidth = @entity.width
    @origHeight = @entity.height
    @origPos = {x: @entity.pos.x, y: @entity.pos.y}
    @origSet = true

  update: (currentTime) ->
    @storeEntitySettings()
    if !@time? || !@startTime?
      return false
    timePassed = currentTime - @startTime - (@delay * 1000)
    if timePassed <= 0
      @entity.setVisible(false)
      return false
    else
      @entity.setVisible(true)
    if timePassed >= (@time * 1000)
      return @end()
    timeFraction = timePassed / (@time * 1000)
    @updatePos(timeFraction)
    @updateSize(timeFraction)
    @updateColor(timeFraction)
#        console.log("(", @entity.id, ") Time: ", currentTime, " last: ", @entity.last, " pos: ", @entity.pos, " size: w: ", @entity.width, " h: ", @entity.height, " offset: ", @entity.offset)

  updatePos: (timeFraction) ->
    if @startPos?
      if typeof @startPos == "function"
        try
          startPos = @startPos.call(@entity)
          @startPos = startPos
        catch e
          startPos = null
      else
        startPos = @startPos
    if @endPos?
      if typeof @endPos == "function"
        try
          endPos = @endPos.call(@entity)
          @endPos = endPos
        catch e
          endPos = null
      else
        endPos = @endPos
    startPos = startPos || @origPos
    endPos = endPos || @origPos
    xPos = startPos.x + ((endPos.x - startPos.x) * timeFraction)
    yPos = startPos.y + ((endPos.y - startPos.y) * timeFraction)
    @entity.pos = {
      x: xPos
      y: yPos
    }
    @entity.last = {
      x: xPos
      y: yPos
    }

  updateSize: (timeFraction) ->
    if typeof @endWidth == "function"
      try #Here to catch any timing issues where updateSize is called before the bullet / vfx is fully initialized
        endWidth = @endWidth.call(@entity)
        @endWidth = endWidth
      catch e
        endWidth = 0
    else
      endWidth = if @endWidth? then @endWidth else @origWidth
    if typeof @endHeight == "function"
      try #Here to catch any timing issues where updateSize is called before the bullet / vfx is fully initialized
        endHeight = @endHeight.call(@entity)
        @endHeight = endHeight
      catch e
        endHeight = 0
    else
      endHeight = if @endHeight? then @endHeight else @origHeight
    startWidth = if @startWidth? then @startWidth else @origWidth
    startHeight = if @startHeight? then @startHeight else @origHeight
    @entity.width = startWidth + (endWidth - startWidth) * timeFraction
    @entity.height = startHeight + (endHeight - startHeight) * timeFraction
#        console.log("Time fraction:" + timeFraction + " width: " + @entity.width + " height: " + @entity.height)
    if @entity.animSheet?
      @entity.animSheet.setWidth(@entity.width)
      @entity.animSheet.setHeight(@entity.height)

  updateColor: (timeFraction) ->
    if typeof @startColor == "function"
      try
        startColor = @startColor.call(@entity)
        @startColor = startColor
      catch e
        startColor = "FFFFFF"
    else
      startColor = @startColor
    if typeof @endColor == "function"
      try
        endColor = @endColor.call(@entity)
        @endColor = endColor
      catch e
        endColor = "FFFFFF"
    else
      endColor = @endColor
    if !@startColor || !@endColor
      return false
    startRGB = startColor.match(/.{1,2}/g) #Split hex string into array of RGB in decimal format (0 - 255 each)
    endRGB = endColor.match(/.{1,2}/g) #Split hex string into array of RGB in decimal format (0 - 255 each)
    finalColor = "0x"
    for i in [0...startRGB.length]
      startInt = Math.round(parseInt(startRGB[i], 16))
      endInt = Math.round(parseInt(endRGB[i], 16))
      diff = endInt - startInt
      newValue = Math.round(startInt + (diff * timeFraction))
      newValueString = newValue.toString(16)
      if newValueString.length == 1
        newValueString = "0" + newValueString
      finalColor += newValueString
    if @entity.animSheet?
      @entity.animSheet.setTint(finalColor)

  end: ->
    @updatePos(1)
    @updateSize(1)
    @updateColor(1)
#        console.log("(", @entity.id, ") END last: ", @entity.last, " pos: ", @entity.pos, " size: w: ", @entity.width, " h: ", @entity.height, " offset: ", @entity.offset)
    if @onFinishedCallback
      @onFinishedCallback()
      @onFinishedCallback = null

  onFinished: (callback) ->
    @onFinishedCallback = callback

module.exports = Animator
