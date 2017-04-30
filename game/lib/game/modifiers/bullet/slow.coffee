InjectedModifier = require("./injected.coffee")

class SlowModifier extends InjectedModifier
  name: "slow"
  description: "Slows enemies by {{slowPercent}} percent for {{duration}} seconds."
  duration: 0
  slowPercent: 0

  constructor: ->

  setup: (duration, slowPercent) ->
    super(duration)
    @slowPercent = slowPercent

  reset: ->
    @slowPercent = 0
    super()

  start: ->
    if !@minion?
      return @end()
    super();
    @minion.speed = (@minion.speed * (1 - (@slowPercent / 100))).round(8)
    @minion.calcVel()
    ts.log.debug("Starting slow on minion at pos ", @minion.pos, " speed ", @minion.speed, " vel ", @minion.vel)

  end: ->
    if @minion?
      ts.log.debug("Ending slow on minion at pos ", @minion.pos, " speed ", @minion.speed, " vel ", @minion.vel)
      @minion.speed = (@minion.speed * (100 / (100 - @slowPercent))).round(8)
      @minion.calcVel()
    super();

module.exports = SlowModifier
