log = require('logger')
cookie = require('cookie')
cookieParser = require('cookie-parser')
connect = require('connect')
config = require('config/lobby')
io = require("../lib/socket-io").io

class GlobalSocket

  constructor: () ->
    io.set 'authorization', (handshakeData, accept) =>
      log.info("Handshake headers: ", handshakeData.headers)
      if handshakeData.headers.cookie
        handshakeData.cookie = cookie.parse(handshakeData.headers.cookie);
        handshakeData.sessionId = cookieParser.signedCookie(handshakeData.cookie[config.cookieKey], config.cookieSecret);
        if handshakeData.cookie[config.cookieKey] == handshakeData.sessionId
          return accept('Cookie is invalid.', false);
      else
        return accept('No cookie transmitted.', false);
      accept(null, true)

module.exports = GlobalSocket
