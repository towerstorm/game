socketIO = require('socket.io')
io = null

init = (app, server) ->
  io = exported.io = socketIO.listen(server)
  io.set('log level', 1);
  io.sockets.on 'connection', (socket) ->
    console.log "Client Connected"
      
exported = {
  init: init,
  io: io
}

module.exports = exported
      
