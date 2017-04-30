_ = require('lodash')
log = require('logger')
uuid = require('node-uuid')
db = require '../lib/rethinkdb-client'
schemas = _.clone(require('config/schemas'))
Model = require './model'

class Queuer extends Model
  tableName: 'queuers'

  constructor: (data) ->
    super(data)

  getInfo: () ->
    return @data

  isInQueuer: (userId) ->
    return userId in @get('userIds')

  accept: (userId, callback) ->
    if userId in @get('confirmedUserIds')
      return callback(new Error("User already confirmed"))
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Queuer.table.get(@get('id'))
      .update({confirmedUserIds: db.row('confirmedUserIds').append(userId)}, {returnChanges: true})
      .run(conn, @defaultUpdateReturnCallback(conn, callback))

  defaultUpdateReturnCallback: (conn, callback) ->
    return (err, updateInfo) =>
      conn.close()
      if err then return callback(err)
      @data = @sanitize(updateInfo.changes[0].new_val)
      callback(null, @)


Queuer.table = db.table('queuers')
Queuer.changeConnections = {}

Queuer.getId = (callback) ->
  _.defer ->
    id = uuid.v4();
    callback(null, id)

Queuer.create = (userIds, callback) ->
  Queuer.getId (err, id) ->
    log.info("Creating queuer with userIds: ", userIds)
    queuer = new Queuer({id, userIds, elo: 1000, joinQueueTime: Date.now(), state: Queuer.STATES.searching})
    queuer.save(callback)

Queuer.defaultCallback = (conn, callback) ->
  return (err, queuerInfo) ->
    conn.close()
    if err then return callback(err, null)
    if !queuerInfo then return callback(new Error("Did not get queuer Info"), null)
    callback(null, new Queuer(queuerInfo))

Queuer.defaultMultiCallback = (conn, callback) ->
  return (err, cursor) ->
    if err
      conn.close()
      return callback(err, null)
    cursor.toArray (err, results) ->
      conn.close()
      queuers = results.map((queuerInfo) -> new Queuer(queuerInfo))
      return callback(null, queuers)

Queuer.defaultUpdateCallback = (conn, callback) ->
  return (err, updateInfo) ->
    conn.close()
    if err then return callback(err)
    callback(null, updateInfo)

Queuer.defaultUpdateReturnCallback = (conn, callback) ->
  return (err, updateInfo) ->
    conn.close()
    if err then return callback(err)
    callback(null, new Queuer(updateInfo.changes[0].new_val))

Queuer.findById = (id, callback) ->
  if !id then return callback(new Error("Invalid ID passed to Queuer.findById"))
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table.get(id).run(conn, Queuer.defaultCallback(conn, callback))

Queuer.findAll = (callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table.run conn, Queuer.defaultMultiCallback(conn, callback)

Queuer.findAllByState = (state, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table.getAll(state, {index: 'state'}).run(conn, Queuer.defaultMultiCallback(conn, callback))

Queuer.findAllByMatchId = (matchId, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table.getAll(matchId, {index: 'matchId'}).run(conn, Queuer.defaultMultiCallback(conn, callback))

Queuer.decline = (id, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table.get(id).update({state: Queuer.STATES.declined}, {returnChanges: true}).run(conn, Queuer.defaultUpdateReturnCallback(conn, callback))

Queuer.updateStateByMatchId = (matchId, state, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table
    .getAll(matchId, {index: 'matchId'})
    .update(db.branch(db.row('matchId').eq(matchId),{state: state},{}), {returnChanges: true}).run(conn, Queuer.defaultUpdateCallback(conn, callback))

Queuer.updateGameByMatchId = (matchId, game, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table
    .getAll(matchId, {index: 'matchId'})
    .update(db.branch(db.row('matchId').eq(matchId),{game: game},{}), {returnChanges: true}).run(conn, Queuer.defaultUpdateCallback(conn, callback))

Queuer.resumeSearching = (matchId, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.table
    .getAll(matchId, {index: 'matchId'})
    .update(db.branch(db.row('matchId').eq(matchId),{state: Queuer.STATES.searching, confirmedUserIds: [], matchId: null, game: null},{}), {returnChanges: true}).run(conn, Queuer.defaultUpdateCallback(conn, callback))

###
  Subscribe to all changes for this user. Returns a new user with new data whenever a change is made, so it's just like findByX
###
Queuer.changes = (id, callback) ->
  connectionId = uuid.v4()
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Queuer.changeConnections[connectionId] = conn
    Queuer.table.changes().filter(db.row('new_val')('id').eq(id)).run conn, (err, cursor) =>
      if err then return callback(err)
      cursor.each (err, data) ->
        if err then return callback(err)
        callback(null, new Queuer(data['new_val']))
  return connectionId

Queuer.closeChangesConnection = (id) ->
  if id? && Queuer.changeConnections[id]?
    Queuer.changeConnections[id].close()
    delete Queuer.changeConnections[id]

Queuer.STATES = {
  searching: "searching"
  waiting: "waiting"          #Temporarily holding this queuer for some other action, defense against race conditions.
  confirming: "confirming"    #6 Players found for match, players need to click confirm to start it
  declined: "declined"        # One or more players in queue declined or failed to click accept in time
  found: "found"              #Match has been found and players should join the game.
}

module.exports = Queuer


