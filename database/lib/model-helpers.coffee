_ = require('lodash')

helpers = {
  ###
    Returns an object of only allowed values and defaults filled in by the schema
  ###
  sanitize: (data, currentData) ->
    data = data || {} #If null data is passed in for some reason just return the current data
    return _.pick(_.defaults(data, currentData), _.keys(currentData))


}

module.exports = helpers
