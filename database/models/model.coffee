_ = require('lodash')
helpers = require('../lib/model-helpers')
schemas = _.clone(require('config/schemas'))
db = require('../lib/rethinkdb-client')
debug = require("debug")("db:model");

noop = ->

class Model
  data: null
  tableName: null

  constructor: (data) ->
    if @tableName
      @data = schemas[@tableName].cols
      @data = @sanitize(data)

  get: (name) ->
    return @data[name]

  set: (name, value) ->
    @data[name] = value

  add: (name, item) ->
    @data[name].push(item)

  remove: (name, item) ->
    for i in [(@data[name].length)..0]
      if @data[name][i] == item
        return @data[name].splice(i, 1)


  ###
    Sanitizes the data passed in ensuring every field is in
    the table schema (so rows are consistent)
  ###
  sanitize: (data) ->
    data = data || {} #If null data is passed in for some reason just return the current data
    schema = schemas[@tableName].cols
    return _.pick(_.defaults(data, schema), _.keys(schema))

  save: (callback = noop) ->
    data = @sanitize(@data);
    if !data then return callback(new Error("Somehow no data passed to save"));
    if !@tableName then return callback(new Error("Somehow no callback passed to save"));
    db.onConnect (err, conn) =>
      if err then return callback(err)
      db.table(@tableName).insert(data, {conflict: 'update'}).run conn, (err, res) =>
        conn.close()
        if err then return callback(err, null)
        callback(null, @)



module.exports = Model
