util = require("util")
rs = require 'randomstring'
_ = require 'lodash'
authConfig = require('config/auth')
userRoles = authConfig.userRoles
userRolesAdvanced = authConfig.userRolesAdvanced
accessLevels = authConfig.accessLevels;
uuid = require('node-uuid')
schemas = _.clone(require('config/schemas'))
async = require 'async'
EasyP = require('easy-pbkdf2')
Model = require './model'
db = require '../lib/rethinkdb-client'
log = require('logger')

easyp = new EasyP({DEFAULT_HASH_ITERATIONS: 32})

noop = ->
#log = (details) -> console.log(details)

class User extends Model
  tableName: 'users'

  constructor: (data) ->
    super(data)

  addOauthProvider: (provider, providerId, data, callback) ->
    email = User.extractEmailFromData(data)
    @set('role', userRoles.user)
    if email? && email != ""
      @set('email', email)
    @saveSocialLogin provider, providerId, (err, details) =>
      if err?
        log.error("Failed to save social login, err: ", err)
      @save(callback)

  saveSocialLogin: (provider, providerId, callback = noop) ->
    if !provider || !providerId
      return callback("Missing param", null)
    socialLogin =
      id: User.getSocialLoginDBId(provider, providerId)
      provider: provider
      userId: @get('id')
    socialLoginSanitized = @sanitizeSocialLogin(socialLogin)
    if socialLoginSanitized
      db.onConnect (err, conn) =>
        if err then return callback(err)
        User.socialLoginTable.insert(socialLoginSanitized).run conn, (err, res) =>
          conn.close()
          callback(err, socialLoginSanitized)

  sanitizeSocialLogin: (details) ->
    if !details? || !details.id? || !details.provider? || !details.userId?
      return false
    details = _.pick(_.defaults(details, schemas.socialLogins.cols), _.keys(schemas.socialLogins.cols))
    return details

  hasFriendRequest: (requesterId) ->
    return _.find(@get('friendRequests'), (friendRequest) -> friendRequest.id is requesterId)

  deleteFriendRequest: (requesterId) ->
    @set('friendRequests', _.reject(@get('friendRequests'), (request) -> request.id == requesterId))

  hasFriend: (friendId) ->
    return _.find(@get('friends'), (friend) -> friend.id is friendId)

  addFriend: (friend) ->
    @add('friends', {id: friend.get('id'), username: friend.get('username')})

  requestFriendship: (userId, callback) ->
    if userId == @get('id') then return callback("User and friend are same", null)
    User.findById userId, (err, otherUser) =>
      if err then return callback(err)
      if otherUser.hasFriendRequest(@get('id'))
        return callback("Request already sent", null)
      if @hasFriend(userId)
        return callback("Already friends", null)
      otherUser.add('friendRequests', {id: @get('id'), username: @get('username')})
      otherUser.save (err, data) ->
        callback(err, data)

  acceptFriend: (requesterId, callback) ->
    if @get('id') == requesterId then return callback(new Error("User and friend are same"), null)
    User.findById requesterId, (err, requesterUser) =>
      if err then return callback(err)
      if !@hasFriendRequest(requesterId)
        return callback(new Error("No friend request found"), null)
      if @hasFriend(requesterId)
        return callback(new Error("Already friends"), null)
      @deleteFriendRequest(requesterId)
      @addFriend(requesterUser)
      requesterUser.addFriend(@)
      async.parallel [((callback) => @save(callback)), ((callback) => requesterUser.save(callback))], (err, success) =>
        if err then return callback(err)
        return callback(null, true)

  declineFriend: (requesterId, callback) ->
    if @get('id') == requesterId then return callback(new Error("User and friend are same"), null)
    User.findById requesterId, (err, requesterUser) =>
      if err then return callback(err)
      if !@hasFriendRequest(requesterId)
        return callback(new Error("No friend request found"), null)
      if @hasFriend(requesterId)
        return callback(new Error("Already friends"), null)
      @deleteFriendRequest(requesterId)
      @save(callback)

  changeUsername: (username, callback) ->
    if @get('role') == userRoles.temp
      return callback(new Error(">You must be registered to set your username"))
    if @get('username')? && !@get('username').match(/guestuser.[a-zA-Z0-9]{4}/i) && !@get('username').match(/bot/)
      return callback(new Error(">You already have a username"))
    if username.length < 3
      return callback(new Error(">Your username must have at least 3 characters"))
    if username.match(/[^a-zA-Z0-9]/)
      return callback(new Error(">Invalid username, username can only include alphanumeric characters and cannot contain spaces"))
    @set('username', username)
    @set('sanitizedUsername', User.sanitizeUsername(username))
    @save(callback)

  addLobbyInvitation: (lobbyId, requesterUsername, callback) ->
    lobbyInvitation = {
      id: lobbyId
      requesterUsername: requesterUsername
      time: Date.now()
    }
    @add('lobbyInvitations', lobbyInvitation)
    @save(callback)

  acceptLobbyInvitation: (lobbyId, callback) ->
    @set('lobbyInvitations', _.reject(@data.lobbyInvitations, {id: lobbyId}))
    @set('activeLobby', lobbyId)
    @save(callback)

  declineLobbyInvitation: (lobbyId, callback) ->
    @set('lobbyInvitations', _.reject(@data.lobbyInvitations, {id: lobbyId}))
    @save(callback)

  findPrivateChat: (friendId) ->
    return _.find(@get('privateChatRooms'), {friendId: friendId})

  startPrivateChat: (chatRoomId, chatRoomName, friendId, callback) ->
    if _.find(@get('privateChatRooms'), {friendId: friendId})
      return callback(new Error("Already chatting with this user"))
    @add('privateChatRooms',
      {
        id: chatRoomId,
        name: chatRoomName,
        friendId: friendId,
        visible: true
      }
    )
    @save(callback)

  openChat: (chatRoomId, callback) ->
    chatRoom = _.find(@get('privateChatRooms'), {id: chatRoomId})
    if chatRoom
      chatRoom.visible = true
    @save(callback)

  closeChat: (chatRoomId, callback) ->
    chatRoom = _.find(@get('privateChatRooms'), {id: chatRoomId})
    if chatRoom
      chatRoom.visible = false
    @save(callback)

  ###
    returns if this user is valid for this accessLevel (specified as a string)
  ###
  hasAccess: (accessLevelName) ->
    if !@get('role')  || !accessLevels[accessLevelName]
      return false
    role = userRolesAdvanced[@get('role')]
    accessLevel = accessLevels[accessLevelName]
    return !!(accessLevel.bitMask & role.bitMask)

  getInfo: ->
    info = _.omit(@data, ['password', 'salt', 'sanitizedUsername'])




User.table = db.table('users')
User.socialLoginTable = db.table('socialLogins')
User.changeConnections = {}

User.getNextId = (callback) ->
  _.defer ->
    id = uuid.v4()
    callback(null, id)

User.getSocialLoginDBId = (provider, providerId) ->
  return provider.substr(0,1) + "_" + providerId

User.defaultCallback = (conn, callback) ->
  return (err, userInfo) ->
    conn.close()
    if err then return callback(err, null)
    if !userInfo then return callback(new Error("Did not get user info"), null)
    callback(null, new User(userInfo))

User.defaultMultiCallback = (conn, callback) ->
  return (err, cursor) ->
    if err
      conn.close()
      return callback(err, null)
    cursor.toArray (err, results) ->
      conn.close()
      users = results.map((userInfo) -> new User(userInfo))
      return callback(null, users)

User.defaultSingleFromMultiCallback = (conn, callback) ->
  return (err, cursor) ->
    if err
      conn.close()
      return callback(err, null)
    cursor.toArray (err, results) ->
      conn.close()
      if !results.length
        return callback(new Error("Failed to find user"), null)
      return callback(null, new User(results[0]))

User.extractEmailFromData = (data) ->
  email = ""
  if data?.emails? && data.emails[0]?.value?
    email = data.emails[0].value
  return email

User.create = (username, password, callback) ->
  User.getNextId (err, userId) =>
    if err then return callback(err)
    easyp.secureHash password, (err, hash, salt) =>
      if err then return callback(err)
      user = new User({
        id: userId
        username: username
        sanitizedUsername: User.sanitizeUsername(username)
        password: hash
        salt: salt
        role: userRoles.user
      });
      user.save(callback)

User.createTempUser = (username, callback) ->
  User.getNextId (err, userId) =>
    if err then return callback(err)
    role = userRoles.temp
    if username == "temp"
      username = "GuestUser." + rs.generate(4)
    if username == "bot"
      role = userRoles.bot
    user = new User({
      id: userId
      username: username
      sanitizedUsername: User.sanitizeUsername(username)
      role: role
    });
    user.save(callback)

User.createOauthUser = (provider, providerId, email, callback) ->
  User.getNextId (err, userId) =>
    if err then return callback(err)
    username = "GuestUser." + rs.generate(4)
    user = new User({
      id: userId
      username: username,
      sanitizedUsername: User.sanitizeUsername(username),
      email: email
      role: userRoles.user
    });
    user.saveSocialLogin provider, providerId, (err, details) =>
      if err?
        log.error("Failed to save social login, err: ", err)
      user.save(callback)

User.findOrCreateOauthUser = (provider, providerId, data, callback) ->
  email = User.extractEmailFromData(data)
  User.findByProviderId provider, providerId, (err, user) =>
    if !err? && user
      return callback(null, user)
    else
      User.createOauthUser provider, providerId, email, (err, user) =>
        return callback(err, user)

User.findById = (id, callback) ->
  if !id then return callback(new Error("Invalid ID passed to User.findById"))
  db.onConnect (err, conn) =>
    if err then return callback(err)
    User.table.get(id).run(conn, User.defaultCallback(conn, callback))

User.findByUsername = (username, callback) ->
  sanitizedUsername = User.sanitizeUsername(username)
  db.onConnect (err, conn) =>
    if err then return callback(err)
    User.table.getAll(sanitizedUsername, {index: 'sanitizedUsername'}).run(conn, User.defaultSingleFromMultiCallback(conn, callback))

User.findByUsernamePassword = (username, password, callback) ->
  User.findByUsername username, (err, user) =>
    if err then return callback(err)
    easyp.verify user.get('salt'), user.get('password'), password, (err, res) =>
      if err then return callback(err)
      if !res then return callback(new Error("Password was not correct"))
      return callback(null, user)

User.findByEmail = (email, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    User.table.getAll(email, {index: 'email'}).run(conn, User.defaultSingleFromMultiCallback(conn, callback));

User.findByProviderId = (provider, providerId, callback) ->
  if !provider || !providerId
    return callback("Missing param", null)
  db.onConnect (err, conn) =>
    if err then return callback(err)
    User.socialLoginTable.get(@getSocialLoginDBId(provider, providerId)).run conn, (err, socialLogin) =>
      conn.close()
      if err then return callback(err)
      if !socialLogin then return callback("Could not find social login", null)
      User.findById socialLogin.userId, (err, user) =>
        if err then return callback(err)
        callback(null, user)

User.findAll = (callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    User.table.run conn, User.defaultMultiCallback(conn, callback)


User.delete = (id, callback) ->
  db.onConnect (err, conn) =>
    if err then return callback(err)
    User.table.get(id).delete().run conn, (err, res) =>
      conn.close()
      callback(err, res)

###
  Subscribe to all changes for this user. Returns a new user with new data whenever a change is made, so it's just like findByX
###
User.changes = (id, callback) ->
  if !id?
    return callback(new Error("No id passed to changes"))
  connectionId = uuid.v4()
  db.onConnect (err, conn) =>
    if err then return callback(err)
    User.changeConnections[connectionId] = conn
    User.table.changes().filter(db.row('new_val')('id').eq(id)).run conn, (err, cursor) =>
      if err then return callback(err)
      cursor.each (err, data) ->
        if err then return callback(err)
        callback(null, new User(data['new_val']))
  return connectionId

User.closeChangesConnection = (id) ->
  if id? && User.changeConnections[id]?
    User.changeConnections[id].close()
    delete User.changeConnections[id]

User.sanitizeUsername = (username) ->
  return username.replace(' ', '').toLowerCase()



module.exports = User
