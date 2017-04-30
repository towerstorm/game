Animation = require("./animation.coffee")

maxVelocity = 1000
minBounceVelocity = 40

_ = require("lodash");

class Entity
  constructor: (x, y, settings) ->
    @reset()
    @_killed = false
    @_destroyed = false
    @id = ++Entity._lastId
    @pos =
      x: x
      y: y
    @drawPos =
      x: x
      y: y
    @last =
      x: x
      y: y
    _.extend(this, settings)
    return

  reset: ->
    @id = 0
    @settings = {}
    @name = null
    @description = null
    @size =
      x: 0
      y: 0
    @offset =
      x: 0
      y: 0
    @pos =
      x: 0
      y: 0
    @drawPos =
      x: 0
      y: 0
    @last =
      x: 0
      y: 0
    @vel =
      x: 0
      y: 0
    @lastVel =
      x: 0
      y: 0
    @zIndex = 0
    @visible = true
    @spawnTick = null
    @anims = {}
    @animSheet = null
    @currentAnim = null
    @alpha = 1
    @health = 0
    @angle = 0
    return

  addAnim: (name, frameTime, sequence, stop) ->
    if !@animSheet
      if ts.isHeadless
        return null
      throw 'No animSheet to add the animation ' + name + ' to.'
    a = new Animation(@animSheet, frameTime, sequence, stop)
    a.name = name
    @anims[name] = a
    if !@currentAnim
      @currentAnim = a
    return a

  update: ->
    isMoving = @vel.x != 0 or @vel.y != 0
    if isMoving
      @last.x = @pos.x
      @last.y = @pos.y
      @updateVelocity(@vel.x, @vel.y)
      mx = @vel.x * ts.system.constantTick
      my = @vel.y * ts.system.constantTick
      if @distanceTravelled?
        @distanceTravelled += Math.abs(mx) + Math.abs(my)
      @pos.x += mx
      @pos.y += my
    return

  updateVelocity: (x, y) ->
    if x?
      @lastVel.x = @vel.x
      @vel.x = x
    if y?
      @lastVel.y = @vel.y
      @vel.y = y
    return

  setVelocity: (x, y) ->
    @vel.x = x
    @vel.y = y
    @lastVel.x = x
    @lastVel.y = y
    return

  interpolatedOffset: (timeOffset) ->
    if !timeOffset?
      timeOffset = 0
    timeSinceLastTick = ts.system.clock.timeSinceLastTick() - timeOffset
    xMove = @lastVel.x * timeSinceLastTick
    yMove = @lastVel.y * timeSinceLastTick
    interpolatedOffset =
      x: xMove
      y: yMove
    #Check if we've passed our target position (it's moving too fast for between updates), if so we don't want to draw this entity
    if xMove != 0 and @last.x + xMove < @pos.x == @last.x > @pos.x
      interpolatedOffset = null
    if yMove != 0 and @last.y + yMove < @pos.y == @last.y > @pos.y
      interpolatedOffset = null
    interpolatedOffset

  draw: ->
    if @currentAnim
      @currentAnim.update()
    if @currentAnim and !@_destroyed and @visible
      interpolatedOffset =
        x: 0
        y: 0
      isMoving = @vel.x != 0 or @vel.y != 0
      if isMoving
        interpolatedOffset = @interpolatedOffset()
      if !interpolatedOffset?
        #                    this.currentAnim.hide(); //This is causing minions to disappear with lag which looks bad
      else
        @drawPos.x = @last.x - (@offset.x) + interpolatedOffset.x - (ts.game.paddingLeft)
        @drawPos.y = @last.y - (@offset.y) + interpolatedOffset.y - (ts.game.paddingTop)
        @currentAnim.draw @drawPos.x, @drawPos.y
    return

  kill: ->
    @_killed = true
    ts.game.killEntity this
    return

  instantKill: ->
    @kill()
    @destroy()
    return

  destroy: ->
    if @animSheet?
      @animSheet.destroy()
    @_destroyed = true
    return

  receiveDamage: (amount, from) ->
    @health = (@health - amount).round(8)
    if @health <= 0
      @kill()
    return

  @_lastId = 0

  #These should go in render order, so if something new is added figure out
  #Where on the z plane it should be drawn, goes back to front in drawing.
  @CTYPE =
    NONE: 0
    GAMEENTITY: 1
    DOODAD: 2
    MINION: 3
    CASTLE: 4
    TOWER: 5
    BULLET: 6
    GEM: 7
    VFX: 8
    MINIONOVERLAY: 9
    TOWEROVERLAY: 10
    TEMPMINION: 11
    TEMPTOWER: 12
    SPAWNPOINT: 13

module.exports = Entity
