#global ts
Animator = require("../modules/animator.coffee")
Entity = require("../../engine/entity.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")
vfxConfig = require("config/vfx")

class GameEntity extends Entity
  ctype: Entity.CTYPE.GAMEENTITY
  
  constructor: (x, y, settings) ->
    @reset()
    super x, y, settings
    @bindDispatcher(ts.game.dispatcher);
    @loadAnimators()
    @checkAlpha()
    @checkScale()
    @setVisible(@visible)


  loadAnimators: ->
    if !@animations?
      return false
    for anim in @animations
      animator = new Animator(@, anim)
      animator.onFinished(@animatorFinished.bind(@))
      @animators.push(animator)

  checkAlpha: ->
    if @alpha? && @animSheet?
      @animSheet.setAlpha(@alpha)

  checkScale: ->
    if @scale? && @scale != 1 && @animSheet?
      @animSheet.resize(@scale)

  reset: ->
    super()
    @owner = null
    @ownerId = null
    @animSheet = null
    @lastMove = {x: 0, y: 0}
    @width = 0
    @height = 0
    @targetPos = null
    @speed = 0
    @frozen = false
    @frozenTimeInterpolationOffset = 0
    @filters = {}
    @selected = false
    @canBeSelected = false
    @animations = []
    @frames = {}
    @animators = []
    @totalAnimatorsFinished = 0
    @animatorsFinishedCallback = null
    if @dispatcherBindings?
      for binding in @dispatcherBindings
        ts.game.dispatcher.off(binding);
    @dispatcherBindings = []
    return

  bindDispatcher: (dispatcher) ->
    hoverBind = dispatcher.on gameMsg.hoverNoSelection, (xPos, yPos) =>
      @handleHover(xPos, yPos)
    @dispatcherBindings.push(hoverBind)
    clickBind = dispatcher.on gameMsg.clickNoSelection, (xPos, yPos) =>
      @handleClick(xPos, yPos)
    @dispatcherBindings.push(clickBind)

  getCenter: () ->
    width = if @width then @width else config.tileSize
    height = if @height then @height else config.tileSize
    centerX = @pos.x + (width / 2)
    centerY = @pos.y + (height / 2)
    centerX -= @offset.x
    centerY -= @offset.y
    return { x: centerX, y: centerY }

  getDrawCenter: (includeOffset = false) ->
    width = if @width then @width else config.tileSize
    height = if @height then @height else  config.tileSize
    centerX = @drawPos.x + (width / 2)
    centerY = @drawPos.y + (height / 2)
    if includeOffset
      centerX -= @offset.x
      centerY -= @offset.y
    return { x: centerX, y: centerY }

  calcVel: ->
    if !@targetPos?
      return false
    if @frozen
      @updateVelocity(0, 0)
      return @vel
    newVel = ts.game.functions.calcVel(@pos, @targetPos, @speed)
    @updateVelocity(newVel.x, newVel.y)
    return @vel

  setTargetPos: (x, y) ->
    @targetPos = {x: x, y: y};
    @calcVel();

  ###
    The hit point is where we want this entity to hit another. So for an
    arrow it will be where the arrowhead is rather than the top left corner
  ###
  getHitPoint: () ->

  # Checks if we are heading towards the target and if not we need to change direction and velocity to go towards it
  # hitCenters - Try and match the centers of the 2 objects rather than the topleft of this object with the center of the other
  checkTarget: (useHitPoint = false) ->
    if @target?
      if @target.ctype == Entity.CTYPE.MINION
        if !@target.canBeShot()
          @target = null
        else if @target.pos?
          targetX = @target.getCenter().x
          targetY = @target.getCenter().y
          @setTargetPos targetX, targetY
        else
          @target = null

  checkReachedTarget: ->
    if @targetPos?
      #Check if we passed our target in the last movement (details on this algorithm in evernote)
      if (@pos.x - @lastMove.x < @targetPos.x) == (@pos.x > @targetPos.x)
        @updateVelocity(0, null);
        @pos.x = @targetPos.x
      if (@pos.y - @lastMove.y < @targetPos.y) == (@pos.y > @targetPos.y)
        @updateVelocity(null, 0)
        @pos.y = @targetPos.y

  hasReachedTarget: (useHitPoint = false) ->
    if !@pos.x? || !@pos.y?
      return false;
    #If target.pos is null it means the target died and its pos has been reset so the bullet should go off @targetPos instead
    if @target? && @target.pos? && @target.ctype == Entity.CTYPE.MINION
      targetX = @target.getCenter().x
      targetY = @target.getCenter().y
    else if @targetPos?
      targetX = @targetPos.x
      targetY = @targetPos.y
    else
      return true
    if @pos.x == targetX && @pos.y == targetY
      # console.log "reached target", @pos, "target", @targetPos
      return true
    return false

  ###
    It looks like it does an async call, but it's really syncronous so we can make this function syncronous too
  ###
  getOwner: () ->
    if @owner then return @owner
    if @ownerId
      ts.game.dispatcher.emit gameMsg.getPlayer, @ownerId, (owner) =>
        @owner = owner
    return @owner


  ###
  *
  * For applying a colour or special pixel filter to this entity
  *
  ###
  applyFilter: (filter) ->

  removeAllFilters: ->

  ###
   * Gets an object representing this minions current state
   *
  ###
  getSnapshot: (snapshot = {}) ->
    for item in ['team', 'health', 'width', 'height', 'size', 'pos', 'offset', 'vel']
      snapshot[item] = @[item]
    return snapshot;


  update: ->
    @frozenTimeInterpolationOffset = 0
    lastxPos = @pos.x
    lastyPos = @pos.y
    super()
    @lastMove.x = @pos.x - lastxPos
    @lastMove.y = @pos.y - lastyPos

  draw: ->
    @updateAnimators()
    super()

  updateAnimators: ->
    time = Date.now()
    for animator in @animators
      animator.update(time)


  kill: ->
    super()

  select: () ->
    if @animSheet
      @animSheet.setTint(config.tint.highlight)
    @selected = true

  deselect: () ->
    if @animSheet
      @animSheet.setTint(config.tint.default)
    @selected = false

  getClickAreaSizeSqrd: ->
    clickAreaSize = config.tileSize / 2
    if ts.ua.touch
      clickAreaSize *= 1.5
    clickAreaSizeSqrd = clickAreaSize * clickAreaSize
    return clickAreaSizeSqrd

  handleHover: (xPos, yPos) ->
    if !@canBeSelected || @selected
      return false
    distToPos = ts.game.functions.getDistSqrd(@getCenter(), {x: xPos, y: yPos})
    if distToPos < @getClickAreaSizeSqrd()
      @animSheet.setTint(config.tint.highlight)
      ts.game.dispatcher.emit gameMsg.entityHover, @
    else
      @animSheet.setTint(config.tint.default)

  handleClick: (xPos, yPos) ->
    if !@canBeSelected
      return false
    distToPos = ts.game.functions.getDistSqrd(@getCenter(), {x: xPos, y: yPos})
    if distToPos < @getClickAreaSizeSqrd()
      ts.game.dispatcher.emit gameMsg.entityClicked, @

  didClickInControlPanel: (xPos, yPos) ->

  handleClickInControlPanel: (xPos, yPos) ->

  interpolatedOffset: () ->
    if @frozen
      @frozenTimeInterpolationOffset = ts.system.clock.timeSinceLastTick();
      return {x: 0, y: 0}
    else
      return super(@frozenTimeInterpolationOffset);

  teleport: (xPos, yPos) ->
    @pos = {x: xPos, y: yPos}
    @last = {x: xPos, y: yPos}

  hasAnimators: ->
    return !!(@animators && @animators.length)

  startAnimators: (type) ->
    @animators.forEach (animator) =>
      if animator.type == type
        animator.start()

  onAnimatorsFinished: (callback) ->
    @animatorsFinishedCallback = callback

  animatorFinished: () ->
    @totalAnimatorsFinished++
    if @totalAnimatorsFinished == @animators.length && @animatorsFinishedCallback?
      @animatorsFinishedCallback()

  setVisible: (visible) ->
    @visible = visible
    if @animSheet?
      @animSheet.setVisible(visible)

  spawnAllVFX: () ->
    if !@vfx || !@vfx.length || ts.isHeadless
      return false
    for name in @vfx
      details = vfxConfig[name]
      if details.instantSpawn
        @spawnVFX(name)

  spawnVFX: (name) ->
    if ts.isHeadless
      return null
    settings = vfxConfig[name]
    spawnPos = {x: @getCenter().x, y: @getCenter().y}
    #            ts.game.hud.addDebugSquare(this.pos.x, this.pos.y, @width, @height, 'green')
    #            ts.game.hud.addDebugSquare(spawnPos.x, spawnPos.y, @width, @height, 'red')
    if settings.spawnDistance?
      directionVector = ts.game.functions.getDirectionVector(@angle, settings.spawnDistance)
      spawnPos.x -= directionVector.x
      spawnPos.y -= directionVector.y
    #Give the target and targetPos to the vfx so it can be positioned based on it if needed
    settings.targetPos = @targetPos
    settings.target = @target
    #console.log("Spawning VFX targetPos: ", item.targetPos, " spawnPos: ", spawnPos)
    return ts.game.spawnEntity GameEntity.CTYPE.VFX, spawnPos.x, spawnPos.y, settings

module.exports = GameEntity
