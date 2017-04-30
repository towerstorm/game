_ = require 'lodash'
schemas = _.clone(require('config/schemas'))
uuid = require 'node-uuid'
async = require 'async'
db = require('../lib/rethinkdb-client')
Model = require('./model')

noop = -> true

class Game extends Model
  tableName: 'games'

  constructor: (data) ->
    super(data)

  updateField: (fieldName, newValue, callback) ->
    @set(fieldName, newValue)
    @save(callback)

  getInfo: ->
    return _.omit(@data, ['ticks', 'snapshot'])

Game.table = db.table('games')

Game.register = (settings, callback) ->
  @getNextGameId (err, id) =>
    settings.id = id
    game = new Game(settings)
    game.save(callback)

Game.getNextGameId = (callback) ->
  id = uuid.v1() #Timestamp based UUID
  callback(null, id)

Game.defaultCallback = (conn, callback) ->
  return (err, gameInfo) ->
    conn.close()
    if err then return callback(err, null)
    callback(null, new Game(gameInfo))

Game.defaultMultiCallback = (conn, callback) ->
  return (err, cursor) ->
    if err
      conn.close()
      return callback(err, null)
    cursor.toArray (err, results) ->
      conn.close()
      games = results.map((gameInfo) -> new Game(gameInfo))
      return callback(null, games)

Game.defaultSingleFromMultiCallback = (conn, callback) ->
  return (err, cursor) ->
    if err
      conn.close()
      return callback(err, null)
    cursor.toArray (err, results) ->
      conn.close()
      if !results.length
        return callback(new Error("Failed to find game"), null)
      return callback(null, new Game(results[0]))


Game.findById = (id, callback) ->
  if !id then return callback("No ID Passed to Game.findById")
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Game.table.get(id).run conn, Game.defaultCallback(conn, callback)

Game.findAll = (callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Game.table.run conn, Game.defaultMultiCallback(conn, callback)

Game.findAllRecent = (callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Game.table.orderBy({index: db.desc('created')}).limit(10).run conn, Game.defaultMultiCallback(conn, callback)

Game.findByState = (state, callback) ->
  if !state then return callback("No state Passed to Game.findByState")
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Game.table.getAll(state, {index: 'state'}).run conn, Game.defaultMultiCallback(conn, callback)

Game.findByCode = (code, callback) ->
  if !code then return callback("No code Passed to Game.findByCode")
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Game.table.getAll(code, {index: 'code'}).run conn, Game.defaultSingleFromMultiCallback(conn, callback)


module.exports = Game
