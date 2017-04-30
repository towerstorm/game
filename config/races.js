var races = require("glob-loader!./races.pattern")
races = _.mapKeys(races, function (value, key) { return key.match(/\/([^\/.]+)\./)[1]; })
module.exports = races
