#global ts
Minion = require("./minion.coffee")
GameEntity = require("./game-entity.coffee")

config = require("config/general")
_ = require("lodash")

class Bullet extends GameEntity
  ctype: GameEntity.CTYPE.BULLET
  name: "bullet"

  constructor: (x, y, settings) ->
    @reset()
    super x, y, settings
    if !@speed && !settings.speed?
      @speed = 400
    @loadAnimations()
    @checkAnimationState()
    @calculateKillDelay()
    @checkAlpha()
    @checkScale()
    @checkAngle()
    @checkTarget()
    @checkInstantTravel()
    @checkInstantDamage()
    @checkAttachToTower()
    @checkStretchToTarget()
    @checkCenteredOnTower()
    @checkReturnToTower()
    @checkInstantDetonate()
    @spawnAllVFX()

  reset: ->
    super()
    @target = null
    @spawner = null
    @speed = 0
    @damage = 0
    @damageMethod = null
    @modifiers = []
    @vfx = []
    @imageNum = null
    @imageName = null
    @idleFrames = null
    @idleFrameTime = null
    @detonateFrames = null
    @detonateFrameTime = null
    @animationState = null
    @loopAnim = null
    @instantTravel = null
    @instantDamage = null
    @instantDetonate = null
    @dontDamageTarget = null
    @attachedToTower = null
    @centeredOnTower = null
    @targetsLocation = null
    @stretchToTarget = null
    @damageDelay = null
    @damageDelayStart = null
    @killDelay = null
    @killDelayStart = null
    @faceTarget = null
    @returnToTower = null
    @startTime = null
    @startPos = null
    @pivot = null
    @debug_hasDetonated = false

  loadAnimations: ->
    @zIndex = @zIndex || config.bullets.zIndex
    @animSheet =  ts.game.cache.getAnimationSheet('bullets/' + @imageName, @width, @height, @zIndex)
    if !@idleFrames? then @idleFrames = 1
    @idleFrameTime = @idleFrameTime || 0.1
    idleFrames = []
    for x in [0...@idleFrames]
      idleFrames.push(x)
    @addAnim "idle", @idleFrameTime, idleFrames, false
    @detonateFrames = @detonateFrames || 0
    @detonateFrameTime = @detonateFrameTime || 0.1
    if @detonateFrames
      detonateFrames = []
      for x in [0...@detonateFrames]
        detonateFrames.push(x)
      @addAnim "detonate", @detonateFrameTime, detonateFrames, true
    @currentAnim = @anims.idle

  getAnimationState: ->
    if !@currentAnim
      return null
    animationState = {
      name: @currentAnim.name
      delta: parseFloat(@currentAnim.timer.delta())
    }
    return animationState

  checkAnimationState: () ->
    if @animationState
      @setAnimationState(@animationState)

  setAnimationState: (animationState) ->
    if !@anims[animationState.name]
      return false
    @currentAnim = @anims[animationState.name]
    @currentAnim.timer.set(-animationState.delta)
    return true

  calculateKillDelay: ->
    animatorTime = if @hasAnimators() then @animators[0].time else 0
    @killDelay = Math.max(animatorTime, (@detonateFrames * @detonateFrameTime), 0) + 0.1

  checkAngle: ->
    if @faceTarget && @angle?
      @checkPivot()
      for name, anim of @anims
        anim.angle = ((parseInt(@angle, 10)) / 180 * Math.PI)
    return true

  checkPivot: () ->
    if @pivot?
      px = @pivot.x
      py = @pivot.y
    else
      px = @width
      py = @height / 2
    @setPivot(px, py)

  setPivot: (x, y) ->
    for name, anim of @anims
      anim.setPivot(x, y)

  ###
    This updates targetPos to be the current location of the minion
    if targetsLocation is true it just returns the current target as we should
    be hitting a location not our specific target
  ###
  checkTarget: ->
    if !@targetsLocation || !@targetPos?
      super()
#          ts.game.hud.addDebugCircle(@targetPos, 5, 'blue', 0.1)
    if @targetsLocation
      @target = null

  checkInstantTravel: ->
    if !@instantTravel || !@targetPos
      return false
    xPos = if @startPos?.x? then @startPos.x else @targetPos.x
    yPos = if @startPos?.y? then @startPos.y else @targetPos.y
    @teleport(xPos, yPos)

  checkInstantDamage: ->
    if !@instantDamage
      return false
    @damageTarget()


  ###
    This function has to find the bullet spawn pos then offset the bullet so the rear of it is at that spawn pos.
    Which is more complicated than it should be because when the bullet is rotated it basically becomes a square and so
    if it's say a laser and is rotated from horizontal to vertical the top left corner will be far away from where
    the actual laser is. This is why I've made the bullet x and y pos at about the center of the bullet then I am offsetting
    the bullet image so it looks right.
  ###
  checkAttachToTower: ->
    if !@attachedToTower
      return false
    bulletSpawnPos = @spawner.getBulletSpawnPos()
    xPos = bulletSpawnPos.x
    yPos = bulletSpawnPos.y
    @checkPivot()
    @teleport(xPos, yPos)
    @vel = {x: 0, y: 0}


  ###
    This function makes the bullet width equal to the distance between the minion and the
    tower. It also scales the height to the same ratio.
  ###
  checkStretchToTarget: ->
    if !@stretchToTarget || !@animSheet
      return false
    distanceToTarget = ts.game.functions.getDist(@spawner.getBulletSpawnPos(), @targetPos)
    sizeRatio = distanceToTarget / @width
#        newHeight = @height * sizeRatio
    @animSheet.setWidth(distanceToTarget)
#        @animSheet.setHeight(newHeight)


  ###
    For AOE Like bullets that just spawn on the tower
    Bullets are placed via their top left but their offset makes
    them really place via their center so all we have to do is teleport
    to where it should spawn and the bullet will center on that pos.
  ###
  checkCenteredOnTower: ->
    if !@centeredOnTower
      return false
    bulletSpawnPos = @spawner.getBulletSpawnPos()
    @teleport(bulletSpawnPos.x, bulletSpawnPos.y)

  checkReturnToTower: ->
    if !@returnToTower
      return false
    bulletSpawnPos = @spawner.getBulletSpawnPos();
    @target = null
    @setTargetPos(bulletSpawnPos.x, bulletSpawnPos.y)
    @angle = ts.game.functions.calcAngleInDegrees(@getCenter(), bulletSpawnPos)
    @checkAngle()
    @targetsLocation = true

  checkInstantDetonate: ->
    if !@instantDetonate
      return false
    @detonate()



  ###
    Gets center offset by the angle the image is at
  ###
  getImageCenter: ->
    pos = _.clone(@pos)
    if @angle?
      #Go to pivot position
#          pos.x += @width
#          pos.y += @height / 2

      #Add half width in direction of angle to get center.
      directionVector = ts.game.functions.getDirectionVector(@angle, @width / 2)
      pos.x -= directionVector.x
      pos.y -= directionVector.y
#          ts.game.hud.addDebugCircle(pos, 10, 'blue')
    return pos

  getDamageCenter: ->
    if @centeredOnTower
      center = @getCenter()
    else if @faceTarget
      center = @getImageCenter()
    else
      center = @targetPos
    return {x: center.x, y: center.y}

  update: ->
    if !@debug_hasDetonated
      ts.log.debug("Calling update on bullet ", @imageName, " at pos ", @pos)
    if !@target? && !@targetPos?
      ts.log.debug("Calling kill on bullet ", @imageName, " at pos ", @pos)
      @kill(); return false;
    @checkDamageDelay()
    @checkKillDelay()
    if @speed > 0
      @checkTarget();
      super()
      @checkReachedTarget()
      hasReachedTarget = @hasReachedTarget()
      if hasReachedTarget
        @detonate()

  checkDamageDelay: ->
    if !@damageDelayStart || !@damageDelay
      return false;
    if ts.getCurrentConstantTime() - @damageDelayStart >= @damageDelay
      @damageTarget()
      @damageDelayStart = null

  checkKillDelay: ->
    if !@killDelayStart || !@killDelay
      return false;
    if ts.getCurrentConstantTime() - @killDelayStart >= @killDelay
      @killDelayStart = null
      @instantKill()

  draw: ->
    if ts.game.fps && ts.game.fps.getFPS() < 5
      @setVisible(false)
    super()

  detonate: ->
    ts.log.debug("Calling detonate on bullet ", @imageName, " at pos ", @pos)
    @debug_hasDetonated = true #For tracing issues only, ensuring client and server are in sync
    @speed = 0
    @startAnimators('detonate')
    if @damageDelay
      @damageDelayStart = ts.getCurrentConstantTime()
    else
      @damageTarget()

    @currentAnim = @anims.detonate
    if @loopAnim
      finishedCallback = () =>
        if @currentAnim?
          @currentAnim.rewind()
    else
      if @currentAnim?
        @currentAnim.rewind()
      finishedCallback = () =>
        @setVisible(false)

    if @hasAnimators() && (@animators[0].time > (@detonateFrames * @detonateFrameTime))
      @onAnimatorsFinished(finishedCallback)
    else if @currentAnim?
      @currentAnim.onFinished(finishedCallback)
    else if !@hasAnimators()
      @setVisible(false)

    if @killDelay
      @killDelayStart = ts.getCurrentConstantTime()
    else
      @instantKill()

  targetIsMinion: ->
    return @target instanceof Minion

  damageTarget: ->
    if @targetIsMinion() && @target.canBeShot() && !@dontDamageTarget
      @target.lastDamageSource = this       #So modifiers like poison can properly set a source. Can't put damage here so modifiers like +gold have time to take effect.
      if @modifiers? && @modifiers.length
        @target.injectModifiers(@modifiers)
      if @damageMethod == "percent"
        @target.receiveDamage((@damage / 100) * @target.maxHealth, this)
      else if @damageMethod == "souls"
        @target.receiveDamage((@damage / @target.souls) * @target.maxHealth, this)
      else
        @target.receiveDamage @damage, this
    @detonateModifiers()

  detonateModifiers: ->
    if @modifiers? && @modifiers.length
      for modifier in @modifiers
        if modifier.detonate?
          modifier.detonate(@)

  kill: ->
    ts.log.debug("Calling kill on bullet ", @imageName)
    super()

module.exports = Bullet
