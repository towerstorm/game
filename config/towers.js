
var towers = require("glob-loader!./towers.pattern")
towers = _.mapKeys(towers, function (value, key) { return key.match(/\/([^\/.]+)\./)[1]; })
for (var tower in towers) {
    towers[tower].towerType = towers[tower].id;
}

module.exports = towers
