require("coffee-script/register");
require('app-module-path').addPath(__dirname + "/../");
var env = process.env.NODE_ENV || 'development'
var http = require('http')

var app = require('./lib/app')
var server = http.createServer(app)
var log = require('logger')

require("./lib/socket-io").init(app, server)

var GlobalSocket = require('./sockets/global-socket.coffee')
var globalSocket = new GlobalSocket()
var UserSocket = require('./sockets/user-socket.coffee')
var userSocket = new UserSocket()
require('./sockets/lobby-socket.coffee')
require('./sockets/queue-socket.coffee')


server.listen(app.get('port'), function() {
  log.info("Lobby running on " + app.get('port'));
});