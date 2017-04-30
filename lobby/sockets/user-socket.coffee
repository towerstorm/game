log = require('logger')
tdb = require('database')
sessionStore = tdb.sessionStore
User = tdb.models.User
io = require("../lib/socket-io").io

class UserSocket
  socket: null

  constructor: () ->
    @socket = io.of('/sockets/user').on "connection", (socket) =>
      sessionId = socket.handshake.sessionId
      log.info("Got new connection to user socket")
      if sessionId
        log.info("Have sessionId of " + sessionId)
        sessionStore.get sessionId, (err, session) =>
          log.info("Got session from sessionStore")
          if err then return log.error("Failed to get user session")
          if !session?.passport?.user?
            return log.error("session.passport.user does not exist for this user when connecting to user socket")
          log.info("Got sessionId: " + sessionId + " user: " + session.passport.user)
          userId = session.passport.user
          User.findById userId, (err, user) =>
            if err then return log.error("Failed to find user of id: " + userId, {err})
            log.info("Found user of id " + userId + " emitting data")
            socket.emit('user.details', user.getInfo())
          connectionId = User.changes userId, (err, user) =>
            if err && (!err.message || !err.message.match(/closed/))
              return log.error("User changes encountered error", {err})
            if user
              log.info("User details changed, new user is: ", user.getInfo())
              socket.emit('user.details', user.getInfo())
          socket.on 'disconnect', ->
            log.info("User disconnected , ending changes connection to userId: " + userId + " connectionId " + connectionId)
            User.closeChangesConnection(connectionId)





module.exports = UserSocket
