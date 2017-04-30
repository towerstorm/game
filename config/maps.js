var _ = require("lodash")
var maps = require("glob-loader!./maps.pattern")
maps = _.mapKeys(maps, function (value, key) { return key.match(/\/([^\/.]+)\./)[1]; })
module.exports = maps
