GameEntity = require("./game-entity.coffee")

config = require("config/general")

class VFX extends GameEntity
  ctype: GameEntity.CTYPE.VFX

  constructor: (x, y, settings) ->
    @reset()
    super(x, y, settings)
    @loadAnimations()
    @checkAlpha()
    @checkInstantDetonate()
    ts.game.hud.addDebugSquare(x, y, @width, @height, 'blue')

  reset: ->
    super()
    @speed = 0
    @imageName = null
    @idleFrames = null
    @idleFrameTime = null
    @detonateFrames = null
    @detonateFrameTime = null
    @loopAnim = null
    @spawnDistance = null
    @instantSpawn = null
    @instantDetonate = null
    @killOnDetonateEnd = null
    @target = null

  loadAnimations: ->
    if @imageName?
      @zIndex = @zIndex || config.vfx.zIndex
      @animSheet =  ts.game.cache.getAnimationSheet('vfx/' + @imageName, @width, @height, @zIndex)
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

  checkInstantDetonate: ->
    if !@instantDetonate
      return false
    @detonate()

  detonate: ->
    @currentAnim = @anims.detonate
    if !@loopAnim
      @currentAnim.rewind()
      finishedCallback = () =>
        if @killOnDetonateEnd
          @target = null
          @targetPos = null;
          @instantKill() #Called so the bullet disappears immediately instead of after an update loop.
    if @hasAnimators()
      @onAnimatorsFinished(finishedCallback)
    else
      @currentAnim.onFinished(finishedCallback)

  update: ->
    super()

  draw: ->
    super()

module.exports = VFX
