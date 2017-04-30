netconfig = require 'config/netconfig'
db = require('database').db
log = require('logger')

class IndexController
  
  constructor: (@app) ->
    
  index: (req, res) ->
    dbConnection = false
    log.info("Bot index page loaded")
    db.onConnect (err, conn) ->
      if !err && conn
        dbConnection = true
        conn.close()

      res.status(200).jsonp({
        server: netconfig.bot.host
        online: true
        dbConnection: dbConnection
      });

module.exports = IndexController