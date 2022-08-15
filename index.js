require("coffee-script/register");
require('app-module-path').addPath(__dirname);
var log = require("logger");
//var respawn = require("respawn");
var spawn = require("child_process").spawn;
var db = require("database").db;
var netconfig = require("config/netconfig");
var path = require("path");

log.init("towerstorm");

db.onConnect(1, function (err, connection) {
    if (err) throw new Error("Unable to connect to RethinkDB. Please ensure it's running on port " + netconfig.db.port);
    
    console.log("Hostname is set to " + netconfig.lobby.host + ". If this is not the url you use to access the game\
        \nyou can change the environment variable HOSTNAME or update it in config/netconfig.js\n");
    
    var apps = ["botmanager", "frontend", "gameserver", "lobby"];
    
    apps.forEach(function(appName) {
        /* var app = respawn(['node', ' ' + appName + "/index.js"], {
            kill: 1000,
            stdout: process.stdout,
            stderr: process.stderr
        });
        console.log("Starting " + appName + " with respawn " + app.pid);
        app.start(); */
        var app = spawn('node', [appName + "/index.js"]);
        app.stdout.pipe(process.stdout);
    });
});
