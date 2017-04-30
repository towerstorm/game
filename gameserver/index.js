require("coffee-script/register")
require('app-module-path').addPath(__dirname + "/../");
var config = require('config/gameserver');
var netconfig = require('config/netconfig');

var env = process.env.NODE_ENV || "development";
if (env == "development") {
  var appName = "Tower Storm Game Server Dev"
} else {
  var appName = "Tower Storm Game Server " + netconfig.gs.host
}

process.env.PORT = netconfig.gs.port;

var http = require('http');
var app = require('./lib/app');
var server = http.createServer(app);
var log = require('logger');

require("./lib/socket-io").init(app, server);

server.listen(app.get('port'), function() {
  log.info("Game Server running on port " + app.get('port'));
});



