###
  this DB is a wrapper around rethinkdb that does all the basic
  connection / instantiation stuff so the models can just worry about performing queries.
###

r = require('rethinkdb')
netconfig = require('config/netconfig')
_ = require 'lodash'
env = process.env.NODE_ENV || 'development'
logger = require('logger')
transports = []

db = r
db.log = new (logger.Logger)({
  transports: transports.concat(logger.getCustomTransports('database'))
})

connection = null
totalOpenConnections = 0
checkRate = 100
db._getConnection = (callback) ->
  stack = new Error().stack
  connectionRequestTime = Date.now()
  connectId = Math.floor(Math.random()*999)
  db.connect {host: netconfig.db.host, port: netconfig.db.port, db: 'towerstorm', timeout: 1, authKey: netconfig.db.authKey}, (err, conn) ->
#    db.log.info("[" + connectId + "] Connected to db in " + (Date.now() - connectionRequestTime) + "ms")
    if err
      logFunc = db.log.error.bind(db.log)
      if err?.message.match(/Handshake/)
        logFunc = db.log.warn.bind(db.log)
      logFunc("Received error opening connection: ", err.message, " stack: ", err.stack, " calling stack: ", stack, " totalOpenConnections: " + totalOpenConnections)
      return callback(err)
    if !conn
      db.log.error("RethinkDB didn't return connection")
      return callback(new Error("RethinkDB didn't return connection"))
    if env == 'debug'
      checkConnectionOpen = (totalChecks) ->
        if !conn || !conn.open
          totalOpenConnections--
        else
          if totalChecks > 0 && totalChecks % 10 == 0
            db.log.error("Connection has not closed in " + (totalChecks * checkRate) + "ms. Conn open is: " + conn.open, {stack})
          setTimeout((-> checkConnectionOpen(++totalChecks)), checkRate)
      checkConnectionOpen(0)
      totalOpenConnections++
    callback(err, conn)

db._fetchConnection = (maxAttempts, totalAttempts, callback) ->
  db._getConnection (err, conn) =>
    totalAttempts++
    if err?.message.match(/Handshake/)
        if (maxAttempts == 0 || (maxAttempts - totalAttempts > 0))
          _.defer =>
            db.log.warn("Rethinkdb connection failed due to Handshake timeout, trying again.", {maxAttempts, totalAttempts, sum: (maxAttempts - totalAttempts)})
            db._fetchConnection(maxAttempts, totalAttempts, callback)
        else
          db.log.error("Critical database error. Handshake timeout failed " + totalAttempts + " times")
          return callback(err)
    else
      return callback(err, conn)
###
  0 attempts = retry forever.
  Defaults to 5 attempts = 25 seconds
###
db.onConnect = (attempts, callback) ->
  if arguments.length == 1
    callback = attempts
    attempts = 10
  db._fetchConnection(attempts, 0, callback)

module.exports = db
