###
 *
 * The dispatcher is for sending pub/sub events around the game so that external interfaces (like the network manager on both client and server) can be notified when
 * game changes occur and update all other clients.
 *
 * Like the networking stuff no longer sites inside of the engine, instead when say a tower is built a buildTower event is sent to the dispatcher which is picked up by the clients
 * external network interface and sent to the server. Then on the server side the tower is built in hte game and a message is sent back to the client letting them know when the
 * tower has completed construction
###

###
Events. Pub/Sub system for Loosely Coupled logic.
Based on Peter Higgins' port from Dojo to jQuery
https://github.com/phiggins42/bloody-jquery-plugins/blob/master/pubsub.js

Re-adapted to vanilla Javascript

@class Dispatcher
###

class Dispatcher
  cache: {}

  constructor: ->
    @cache = {}

  ###
  Events.emit
  e.g.: Events.emit("/Article/added", [article], this);

  @class Events
  @method emit
  @param topic {String}
  @param args {Array}
  @param scope {Object} Optional
  ###
  emit: (topic) ->
    args = Array.prototype.slice.call(arguments);
    args = args.slice(1)

    if @cache[topic]
      thisTopic = @cache[topic]
      i = thisTopic.length - 1
      while i >= 0
        thisTopic[i].apply null or this, args or []
        i -= 1
    return true


  ###
  Events.on
  e.g.: Events.on("/Article/added", Articles.validate)

  @class Events
  @method on
  @param topic {String}
  @param callback {Function}
  @return Event handler {Array}
  ###
  on: (topic, callback) ->
    @cache[topic] = []  unless @cache[topic]
    @cache[topic].push callback
    return [topic, callback]


  ###
  Events.off
  e.g.: var handle = Events.on("/Article/added", Articles.validate);
  Events.off(handle);

  @class Events
  @method off
  @param handle {Array}
  @param completly {Boolean}
  @return {type description }
  ###
  off: (handle, completly) ->
    t = handle[0]
    if @cache[t]
      i = @cache[t].length - 1
      while i >= 0
        if @cache[t][i] is handle[1]
          @cache[t].splice i, 1
          delete @cache[t]  if completly
        i -= 1
    return true

  reset: () ->
    @cache = {}

module.exports = Dispatcher
