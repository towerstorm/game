InjectedModifier = require("./injected.coffee")

class FreezeModifier extends InjectedModifier
  name: "freeze"
  description: "Freezes enemies completely for {{duration}} seconds."

  setup: (duration) ->
    super(duration)

  draw: ->

  start: ->
    if !@minion?
      return @end()
    super();
    @minion.frozen = true
    @minion.calcVel()
    ts.log.debug("Starting freeze on minion at pos ", @minion.pos)

  end: ->
    if @minion?
      ts.log.debug("Ending freeze on minion at pos ", @minion.pos)
      @minion.frozen = false
      @minion.calcVel()
    super();

module.exports = FreezeModifier
