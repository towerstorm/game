_ = require "lodash"

class DispatcherMock
  dispatcherBinds: {}
  dispatcherMessages: {}

  emit: (msg) ->
    args = Array.prototype.slice.apply(arguments, [1]);
    this.dispatcherMessages[msg] = args
    if this.dispatcherBinds[msg]?
      this.dispatcherBinds[msg].apply(this, args)

  on: (msg, func) ->
    this.dispatcherBinds[msg] = func;


module.exports = DispatcherMock