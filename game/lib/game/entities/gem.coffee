Timer = require("../../engine/timer.coffee")
Doodad = require("./doodad.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")

class Gem extends Doodad
  ctype: Doodad.CTYPE.GEM
  name: "gem"

  constructor: (x, y, settings) ->
    @reset()
    super(x, y, settings);
    @animSheet = ts.game.cache.getAnimationSheet('soul-white.png', 41, 41, config.gems.zIndex)
    @size = {x: 41, y: 41}
    @spawnTick = ts.getCurrentTick()
    @canBeSelected = true
    @startOffset = settings.offset || {x: 0, y: 0}
    #We don't want to set an anim / render if it's not a gem for us to gather.
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player? && settings.playerId == player.getId()
        @addAnim("idle", 0.05, [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
        @currentAnim = @anims.idle;
    @floatDirection = -1
    gemConfig = config.gems
    @floatSpeed = gemConfig.floatSpeed
    @floatMax = gemConfig.floatMax

  reset: ->
    super()
    @floatDirection = 0
    @floatSpeed = 0
    @floatMax = 0
    @minionType = null
    @playerId = null
    @collected = false
    @collectConfirmed = false
    @canBeSelected = false
    @startOffset = null

  collect: ->
    if @collected
      return false
    @setVisible(false)
    @collected = true

  collectConfirm: ->
    if !@collectConfirmed
      ts.game.dispatcher.emit gameMsg.collectedGem, @playerId, @minionType
      @collect();
      @collectConfirmed = true
    @kill();

  draw: ->
    #In here so the server / bots don't run this code as they don't need to
    floatMin = 0 + @startOffset.y
    floatMax = @floatMax + @startOffset.y
    @offset.y += @floatDirection * @floatSpeed
    if (@offset.y > floatMax && @floatDirection > 0) || (@offset.y <= floatMin && @floatDirection < 0)
      @floatDirection = -@floatDirection
    super()


  checkForSuicide: () ->
    if @_killed
      return false
    if ts.game.settings.mode == config.modes.tutorial
      return false
    timeUntilDeath = config.gemExpiryTime
    ticksUntilDeath = timeUntilDeath / Timer.constantStep
    if ts.getCurrentTick() > (@spawnTick + ticksUntilDeath)
      @suicide();

  suicide: ->
    ts.game.dispatcher.emit gameMsg.gemSuicide, @

  update: ->
    super();
    @checkForSuicide()

module.exports = Gem
