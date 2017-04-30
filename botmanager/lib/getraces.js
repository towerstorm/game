require('app-module-path').addPath(__dirname + "/../../");
var bulkLoad = require("config/bulk-load");
var _ = require("lodash");

var maps = bulkLoad("maps");
var map = maps["deep-space-collision"];



var spawnPoint = _(map.spawnPoints).filter({team: 0}).sample()
console.log("spawnpoint: ", spawnPoint)