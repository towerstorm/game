_ = require('lodash')
uuid = require('node-uuid')
tdb = require('database')
db = tdb.db
schemas = _.clone(tdb.schemas)
Model = tdb.models.Model

class Lobby extends Model
  tableName: 'lobbies'

  constructor: (data) ->
    super(data)

  bindSocket: () ->

  ###
    Returns JSON object of all info players can retrieve.
    Just returns data for now but may be more sanitized in the future.
  ###
  getInfo: () ->
    return @data

  addUser: (userId, username, callback) ->
    if @isInLobby(userId)
      return callback(new Error("You are already in the lobby"))
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Lobby.table.get(@get('id')) #Done in one update to prevent race conditions
      .update({players: db.row('players').append({id: userId, username: username})}, {returnChanges: true})
      .run(conn, @defaultUpdateReturnCallback(conn, callback))

  inviteUser: (userId, callback) ->
    if @isInLobby(userId)
      return callback(new Error("User is already in lobby"))
    if userId in @get('invitedUserIds')
      return callback(new Error("User has already been invited"))
    if userId in @get('declinedUserIds')
      return callback(new Error("User has already declined joining this game."))
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Lobby.table.get(@get('id')) #Done in one update to prevent race conditions
      .update({invitedUserIds: db.row('invitedUserIds').append(userId)}, {returnChanges: true})
      .run(conn, @defaultUpdateReturnCallback(conn, callback))

  acceptInvitation: (userId, username, callback) ->
    if @isInLobby(userId)
      return callback(new Error("You are already in the lobby"))
    if userId not in @get('invitedUserIds')
      return callback(new Error("You have not been invited to this lobby"))
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Lobby.table.get(@get('id')) #Done in one update to prevent race conditions
      .update({
        players: db.row('players').append({id: userId, username: username})
        invitedUserIds: db.row('invitedUserIds').difference([userId])
      }, {returnChanges: true})
      .run(conn, @defaultUpdateReturnCallback(conn, callback))

  declineInvitation: (userId, callback) ->
    if userId not in @get('invitedUserIds')
      return callback(new Error("You have not been invited to this lobby"))
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Lobby.table.get(@get('id')) #Done in one update to prevent race conditions
      .update({
          declinedUserIds: db.row('declinedUserIds').append(userId)
          invitedUserIds: db.row('invitedUserIds').difference([userId])
        }, {returnChanges: true})
      .run(conn, @defaultUpdateReturnCallback(conn, callback))

  quit: (userId, callback) ->
    _.remove(@get('players'), {id: userId})
    @save(callback)

  isHost: (userId) ->
    return userId == @get('hostUserId')

  isInLobby: (userId) ->
    return _.find(@get('players'), {id: userId})

  getPlayerIds: () ->
    return _.map(@get('players'), (player) -> player.id)

  queue: (queuerId, callback) ->
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Lobby.table.get(@get('id')) #Done in one update to prevent race conditions
      .update({active: false, queuerId: queuerId}, {returnChanges: true})
      .run(conn, @defaultUpdateReturnCallback(conn, callback))

  destroy: (callback) ->
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Lobby.table.get(@get('id')) #Done in one update to prevent race conditions
      .update({active: false}, {returnChanges: true})
      .run(conn, @defaultUpdateReturnCallback(conn, callback))

  defaultUpdateReturnCallback: (conn, callback) ->
    return (err, updateInfo) =>
      conn.close()
      if err then return callback(err)
      @data = @sanitize(updateInfo.changes[0].new_val)
      callback(null, @)




Lobby.table = db.table('lobbies')
Lobby.changeConnections = {}

Lobby.getId = (callback) ->
  _.defer ->
    id = uuid.v4();
    callback(null, id)

Lobby.create = (hostUserId, hostUsername, callback) ->
  Lobby.getId (err, id) ->
    lobby = new Lobby({id, hostUserId, players: [{id: hostUserId, username: hostUsername}], chatRoomId: uuid.v4()})
    lobby.save(callback)

Lobby.defaultCallback = (conn, callback) ->
  return (err, lobbyInfo) ->
    conn.close()
    if err then return callback(err, null)
    if !lobbyInfo then return callback(new Error("Did not get lobby Info"), null)
    callback(null, new Lobby(lobbyInfo))

Lobby.defaultSingleFromMultiCallback = (conn, callback) ->
  return (err, cursor) ->
    if err
      conn.close()
      return callback(err, null)
    cursor.toArray (err, results) ->
      conn.close()
      if !results.length
        return callback(new Error("Failed to find lobby"), null)
      return callback(null, new Lobby(results[0]))

Lobby.findById = (id, callback) ->
  if !id then return callback(new Error("Invalid ID passed to Lobby.findById"))
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Lobby.table.get(id).run(conn, Lobby.defaultCallback(conn, callback))

Lobby.findByQueuerId = (id, callback) ->
  if !id then return callback(new Error("Invalid ID passed to Lobby.findByQueuerId"))
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Lobby.table.getAll(id, {index: 'queuerId'}).run(conn, Lobby.defaultSingleFromMultiCallback(conn, callback))

###
  Subscribe to all changes for this user. Returns a new user with new data whenever a change is made, so it's just like findByX
###
Lobby.changes = (id, callback) ->
  if !id? then return callback(new Error("Undefined or null id passed to changes"))
  connectionId = uuid.v4()
  db.onConnect (err, conn) =>
    if err then return callback(err)
    Lobby.changeConnections[connectionId] = conn
    Lobby.table.changes().filter(db.row('new_val')('id').eq(id)).run conn, (err, cursor) =>
      if err then return callback(err)
      cursor.each (err, data) ->
        if err then return callback(err)
        callback(null, new Lobby(data['new_val']))
  return connectionId

Lobby.closeChangesConnection = (id) ->
  if id? && Lobby.changeConnections[id]?
    Lobby.changeConnections[id].close()
    delete Lobby.changeConnections[id]







module.exports = Lobby