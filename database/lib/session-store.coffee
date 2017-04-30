connect = require('connect')
RDBStore = require('./rethinkdb-store')(connect)
netconfig = require('config/netconfig')

sessionStore = new RDBStore({
  flushOldSessIntvl: 60000,
  table: 'sessions',
  clientOptions: {
    db: 'towerstorm'
    host: netconfig.db.host
    port: netconfig.db.port
    authKey: netconfig.db.authKey
  }
})

module.exports = sessionStore
