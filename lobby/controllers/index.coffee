netconfig = require 'config/netconfig'
db = require('database').db

class IndexController
  constructor: (@app) ->
    
  index: (req, res) ->
    dbConnection = false
    db.onConnect (err, conn) ->
      if !err && conn
        dbConnection = true
        conn.close()

      res.status(200).jsonp({
        server: netconfig.lobby.host
        online: true
        dbConnection: dbConnection
      });


  whoami: (req, res) ->
    res.json {hello: 'world'}

  closeWindow: (req, res) ->
    res.writeHead(200, {'Content-Type': 'text/html'})
    res.end('<script>window.close()</script>');


module.exports = new IndexController()