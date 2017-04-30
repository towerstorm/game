
var database = {
  db: require('./lib/rethinkdb-client'),
  sessionStore: require('./lib/session-store'),
  schemas: require('config/schemas'),
  authConfig: require('config/auth'),
  netconfig: require('config/netconfig'),
  models: {
    Game:  require('./models/game'),
    Model: require('./models/model'),
    Queuer: require('./models/queuer'),
    User: require('./models/user')
  }
}

module.exports = database