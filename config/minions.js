var minions = require("glob-loader!./minions.pattern")
minions = _.mapKeys(minions, function (value, key) { return key.match(/\/([^\/.]+)\./)[1]; })
module.exports = minions
