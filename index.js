require("coffee-script/register");
require('app-module-path').addPath(__dirname);
var log = require("logger");
var respawn = require("respawn");
var db = require("database").db;
var netconfig = require("config/netconfig");
var path = require("path");

log.init("towerstorm");

db.onConnect(1, function (err, connection) {
    if (err) throw new Error("Unable to connect to RethinkDB. Please ensure it's running on port " + netconfig.db.port);
    
    var apps = ["botmanager", "frontend", "gameserver", "lobby"];
    
    apps.forEach(function(appName) {
        var app = respawn(['node', path.join(__dirname, './' + appName + "/index.js")], {
            kill: 1000,
            stdout: process.stdout,
            stderr: process.stderr
        });
        app.start();
    });
});
