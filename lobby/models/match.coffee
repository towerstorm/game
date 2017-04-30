_ = require('lodash')
tdb = require('database')
db = tdb.db
schemas = _.clone(tdb.schemas)
Model = tdb.models.Model

class Match extends Model
  tableName: 'matches'

  constructor: (data) ->
    super(data)

  getInfo: () ->
    return @data


