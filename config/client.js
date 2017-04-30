
window.config = window.config || {};

var cf = window.config;

cf.bullets = require("./bullets/*.js", {mode: "hash"});
cf.gameMsg = require("./game-messages.js");
cf.general = require("./general.js");
cf.maps = require("./maps/*.js", {mode: "hash"});
cf.minions =  require("./minions/*.js", {mode: "hash"});
cf.netMsg = require("./net-messages.js");
cf.races = require("./races/*.js", {mode: "hash"});
cf.towers = require("./towers/*.js", {mode: "hash"});

for (var tower in cf.towers) {
    cf.towers[tower].towerType = cf.towers[tower].id;
}