log = require('logger')
tdb = require('database')
sessionStore = tdb.sessionStore
Queuer = tdb.models.Queuer
io = require("../lib/socket-io").io

class QueueSocket
  socket: null

  constructor: ->
    @socket = io.of('/sockets/lobby/').on "connection", (socket) =>
      sessionId = socket.handshake.sessionId
      log.info("Got new connection to lobby socket")
      if sessionId
        sessionStore.get sessionId, (err, session) =>
          if err then return log.error("Failed to get user session")
          log.info("Got sessionId: ", sessionId, " user: ", session.passport.user)
          userId = session.passport.user
          @bindActions(socket, userId)

  bindActions: (socket, userId) ->
    socket.on 'queue.listen', (queuerId) =>
      log.info("User " + userId + " sent queue.listen")
      Queuer.findById queuerId, (err, queuer) =>
        if err then return @logErr(err)
        if !queuer.isInQueuer(userId)
          return @logErr({uMsg: "You are not in this queue", err})
        socket.emit('queue.details', queuer.getInfo())
        log.info("User " + userId + " sent initial queue.details", queuer.getInfo())
        connectionId = Queuer.changes queuerId, (err, queuer) =>
          if err && (!err.message || !err.message.match(/closed/))
            return @logErr(err)
          if queuer
            log.info("User " + userId + " sent queue.details change", queuer.getInfo())
            socket.emit('queue.details', queuer.getInfo())
        socket.on 'disconnect', ->
          log.info("Queuer socket disconnected , ending changes connection to queuerId: " + queuerId + " connectionId: " + connectionId)
          Queuer.closeChangesConnection(connectionId)


  logErr: (err) ->
    log.error("socket error", {err})
    # TODO: Add error sending /logging





module.exports = new QueueSocket()
