class Modifier
  name: null
  description: null
  type: "modifier"

  setup: ->

  reset: ->
    name = null
    description = null

  draw: ->

  getDescription: ->
    if !@description?
      return ""
    description = @description
    variables = description.match(/{{([a-zA-Z]+)}}/g);
    if variables?
      for variable in variables
        variableName = variable.replace(/[{}]/g, "")
        value = @[variableName]
        if value?
          description = description.replace(variable, value)
    return description

  start: ->

  end: ->
    @kill()

  kill: ->
    ts.game.modPool.addModToPool(@)

module.exports = Modifier
