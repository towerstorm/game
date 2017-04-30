FreezeModifier = require("./freeze.coffee")

class StunModifier extends FreezeModifier
  name: "stun"
  description: "Stuns enemies completely for {{duration}} seconds."

  draw: ->

module.exports = StunModifier
