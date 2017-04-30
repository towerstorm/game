angular.module("makeRange", []).filter("makeRange", ->
  makeRange = (input)->
    switch input.length
      when 1
        lowBound = 0
        highBound = parseInt(input[0]) - 1
      when 2
        lowBound = parseInt(input[0])
        highBound = parseInt(input[1])
      else
        return input
    result = []
    i = lowBound

    while i <= highBound
      result.push i
      i++
    return result
  return makeRange
)
