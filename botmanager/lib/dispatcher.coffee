class Dispatcher
  cache: {}

  constructor: ->
    @cache = {}

  ###
  Usage: dispatcher.emit "topic", arg1, arg2
  ###
  emit: (topic) =>
    # Can pass either an array of items or each item to emit and it will perform the callbacks correctly
    args = Array.prototype.slice.call(arguments);
    args = args.slice(1)

    if @cache[topic]
      thisTopic = @cache[topic]
      i = thisTopic.length - 1
      while i >= 0
        thisTopic[i].apply null or this, args or []
        i -= 1

  ###
  Usage: dispatcher.on "topic", callback
  ###
  on: (topic, callback) =>
    @cache[topic] = []  unless @cache[topic]
    @cache[topic].push callback
    [topic, callback]


  ###
  Usage: dispatcher.off "topic", completelyKillTopic
  ###
  off: (handle, completly) =>
    t = handle[0]
    if @cache[t]
      i = @cache[t].length - 1          
      while i >= 0
        if @cache[t][i] is handle[1]
          @cache[t].splice i, 1
          delete @cache[t]  if completly
        i -= 1
    return true

  reset: =>
    @cache = {}

module.exports = Dispatcher