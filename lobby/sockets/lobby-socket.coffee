log = require('logger')
tdb = require('database')
sessionStore = tdb.sessionStore
Lobby = require('../models/lobby')
io = require("../lib/socket-io").io

class LobbySocket
  socket: null

  constructor: ->
    @socket = io.of('/sockets/lobby/').on "connection", (socket) =>
      sessionId = socket.handshake.sessionId
      log.info("Got new connection to user socket")
      if sessionId
        sessionStore.get sessionId, (err, session) =>
          if err then return log.error("Failed to get user session")
          log.info("Got sessionId: ", sessionId, " user: ", session.passport.user)
          userId = session.passport.user
          @bindActions(socket, userId)

  bindActions: (socket, userId) ->
    socket.emit('lobby.details', 'test')
    socket.on 'lobby.listen', (lobbyId) =>
      log.info("User " + userId + " sent lobby.listen")
      Lobby.findById lobbyId, (err, lobby) =>
        if err then return @logErr(err)
        if !lobby.isInLobby(userId)
          return @logErr({uMsg: "You are not in this lobby", err})
        socket.emit('lobby.details', lobby.getInfo())
        log.info("User " + userId + " sent initial lobby.details", lobby.getInfo())
        connectionId = Lobby.changes lobbyId, (err, lobby) =>
          if err && (!err.message || !err.message.match(/closed/))
            return @logErr(err)
          if lobby
            log.info("User " + userId + " sent lobby.details change", lobby.getInfo())
            socket.emit('lobby.details', lobby.getInfo())
        socket.on 'disconnect', ->
          log.info("Lobby socket disconnected , ending changes connection to lobbyId: " + lobbyId + " connectionId: " + connectionId)
          Lobby.closeChangesConnection(connectionId)


  logErr: (err) ->
    log.error("socket error", {err})
    # TODO: Add error sending /logging





module.exports = new LobbySocket()
