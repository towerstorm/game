require("coffee-script/register");
require('app-module-path').addPath(__dirname + "/../");
var env = process.env.NODE_ENV || "development";

if (env == "development") {
  require('longjohn');
}

var log = require('logger');

var app = require('./lib/app');
var http = require("http");


http.createServer(app).listen(app.get("port"), function() { 
  log.info("Bot Manager running on port " + app.get("port"));
});

