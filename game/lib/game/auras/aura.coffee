class Aura
  name: null
  description: null
  target: null
  owner: null

  constructor: ->

  setup: ->

  reset: ->

  setOwner: (@owner) ->
  setTarget: (@target) ->

  start: ->

  end: ->

  getDescription: ->
    description = @description
    variables = description.match(/{{([a-zA-Z]+)}}/g);
    if variables?
      for variable in variables
        variableName = variable.replace(/[{}]/g, "")
        value = @[variableName]
        if value?
          description = description.replace(variable, value)
    return description

module.exports = Aura
