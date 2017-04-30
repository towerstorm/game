
_ = require "lodash"
assert = require "assert"

class SocketMock
  socketBinds: {}
  socketMessages: {}

  on: (msg, callback) ->
    @socketBinds[msg] = callback

  #Doesn't call binds as emit goes to server, on recieves from server, so it's not realistic for this to trigger it
  emit: (msg) ->
    args = Array.prototype.slice.apply(arguments, [1]);
    @socketMessages[msg] = args

  #Triggers the socket as if it recieved a message from the network
  trigger: (msg) ->
    args = Array.prototype.slice.apply(arguments, [1]);
    assert @socketBinds[msg]?
    @socketBinds[msg].apply(this, args)

  disconnect: ->


module.exports = SocketMock
