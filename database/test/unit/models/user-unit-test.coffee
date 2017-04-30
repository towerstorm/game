assert = require 'assert'
_ = require 'lodash'
schemas = _.clone(require('config/schemas'))
authConfig = require('config/auth')
userRoles = authConfig.userRoles
accessLevels = authConfig.accessLevels;
proxyquire = require('proxyquire').noCallThru()
mocks = require('../mocks')
sinon = require 'sinon'

mockDbHelpers = {}
mockDb = {
  table: ->
}
mockConnection = {close: ->}
User = null
user = null
userId = "123abc"

describe "User", ->
  beforeEach ->
    User = proxyquire('../../../models/user',  {
      '../lib/rethinkdb-client': mockDb
    })
    user = new User()
    User.getNextUserId = (callback) ->
      callback(null, userId)
    User.table = mocks.table(user)
    User.socialLoginTable = mocks.table(user)
    mockDb.onConnect = (callback) -> callback(null, mockConnection)
    sinon.stub(User.prototype, 'save').callsArgWith(0, null, user)

  afterEach ->
    if User.prototype.save.restore?
      User.prototype.save.restore()

  describe "get", ->

  describe "set", ->

  describe "add", ->

  describe "validate", ->

  describe "hasFriendRequest", ->

  describe "deleteFriendRequest", ->

  describe "hasFriend", ->

  describe "addFriend", ->

  describe "friends", ->
    mainUserId = "123"; otherUserId = "456";
    otherUser = null;
    savedMainUser = false; savedOtherUser = false;
    beforeEach ->
      user = new User({id: mainUserId, username: "mewmew", friends: [], friendRequests:[]})
      otherUser = new User({id: otherUserId, username: "lala", friends: [], friendRequests:[]})
      savedMainUser = false; savedOtherUser = false;
      User.findById = (id, callback) ->
        if id == mainUserId then return callback(null, user)
        if id == otherUserId then return callback(null, otherUser)
      User.prototype.save = (callback) ->
        if @get('id') == mainUserId then savedMainUser = true
        if @get('id') == otherUserId then savedOtherUser = true
        callback(null, @)

    describe "requestFriendship", ->
      it "Should return callback error if fromUserId == toUserId", (done) ->
        user.data.id = "aaa"
        user.requestFriendship "aaa", (err, success) ->
          assert err?
          assert !success?
          done()

      it "Should return callback error if fromUserId or toUserId don't exist", (done) ->
        User.findById = (id, callback) ->
          callback("Doesn't exist", null)
        user.requestFriendship otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "Should add the fromUserId to the friendRequests array on toUserId", (done) ->
        user.requestFriendship otherUserId, (err, success) ->
          assert.deepEqual user.data.friendRequests, []
          assert.deepEqual otherUser.data.friendRequests, [{id: mainUserId, username: "mewmew"}]
          assert.equal savedOtherUser, true
          done()

      it "Should return request already sent error if there is already a pending friend request", (done) ->
        otherUser.data.friendRequests = [{id: mainUserId, username: "mewmew"}]
        user.requestFriendship otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "Should return already friends error if these people are already friends", (done) ->
        user.data.friends = [{id: otherUserId, username: "lala"}]
        user.requestFriendship otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

    describe "acceptFriend", ->
      it "Should return callback error if fromUserId or toUserId don't exist", (done) ->
        User.findById = (id, callback) ->
          callback("Doesn't exist", null)
        user.acceptFriend otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "Should return no request found if there is no friend request from requester -> user", (done) ->
        user.data.friendRequests = []
        user.acceptFriend otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "Should return already friends if they are already friends", (done) ->
        user.data.friends = [{id: otherUserId}]
        user.acceptFriend otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "If all is good should add each other as friends and save each user", (done) ->
        user.data.friendRequests = [{id: otherUserId, username: "lala"}]
        user.acceptFriend otherUserId, (err, success) ->
          assert.deepEqual user.data.friends, [{id: otherUserId, username: "lala"}]
          assert.equal savedMainUser, true
          assert.deepEqual otherUser.data.friends, [{id: mainUserId, username: "mewmew"}]
          assert.equal savedOtherUser, true
          done()

      it "If all is good should remove the friend request but keep others", (done) ->
        user.data.friendRequests = [{id: otherUserId, username: "lala"}, {id: "991", username: "bilbo"}]
        user.acceptFriend otherUserId, (err, success) ->
          assert.deepEqual user.data.friendRequests, [{id: "991", username: "bilbo"}]
          done()

    describe "declineFriend", ->
      it "Should return callback error if fromUserId or toUserId don't exist", (done) ->
        User.findById = (id, callback) ->
          callback("Doesn't exist", null)
        user.declineFriend otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "Should return no request found if there is no friend request from requester -> user", (done) ->
        user.data.friendRequests = []
        user.declineFriend otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "Should return already friends if they are already friends", (done) ->
        user.data.friends = [{id: otherUserId}]
        user.declineFriend otherUserId, (err, success) ->
          assert err?
          assert !success?
          done()

      it "If all is good should remove the friend request but not add the friend", (done) ->
        user.data.friendRequests = [{id: otherUserId, username: "lala"}, {id: "991", username: "bilbo"}]
        user.declineFriend otherUserId, (err, success) ->
          assert.deepEqual user.data.friendRequests, [{id: "991", username: "bilbo"}]
          assert.deepEqual user.data.friends, []
          done()

  describe "changeUsername", ->
    beforeEach ->
      User.findById = (id, callback) ->
        callback(null, user)
      user.save = (callback) ->
        callback(null, @)

    it "Should set the username to the new username if their current name is GuestUser.xxxx", (done) ->
      user.data.username = "GuestUser.z6G8"
      user.changeUsername "Awesome", (err, data) ->
        assert !err?
        assert.equal user.data.username, "Awesome"
        assert.equal user.data.sanitizedUsername, "awesome"
        done()

    it "Should not change their username if their current name is not GuestUser.xxx", (done) ->
      user.data.username = "stupidface"
      user.changeUsername "Awesome", (err, data) ->
        assert err?
        assert.equal user.data.username, "stupidface"
        done()

    it "Should not allow users to have non alphanumeric characters in their name", (done) ->
      user.data.username = "GuestUser.z6G8"
      user.changeUsername "$$Winnar", (err, data) ->
        assert err?
        assert.equal user.data.username, "GuestUser.z6G8"
        done()

  describe "addLobbyInivitation", ->

  describe "acceptLobbyInvitation", ->

  describe "declineLobbyInvitation", ->

  describe "findPrivateChatId", ->
    it "Should return the private chat if the user is talking to this friend", ->
      user.data.privateChatRooms = [{chatId: '123', name: 'friend', friendId: "abc123"}]
      assert.equal user.findPrivateChat('abc123'), user.data.privateChatRooms[0]

    it "Should return null if there is no private chat with this friendId", ->
      user.data.privateChatRooms = [{chatId: '123', name: 'friend', friendId: "abc123"}]
      assert.equal user.findPrivateChat('nnas'), null

  describe "startPrivateChat", ->
    it "Should error if we're already chatting with this friend", (done) ->
      user.data.privateChatRooms = [{friendId: "abc123"}]
      user.startPrivateChat 123, 'name', "abc123", (err, res)  ->
        assert err
        assert.equal err.message, "Already chatting with this user"
        done()

    it "Should create privateChatRoom if we aren't chatting with this user", (done) ->
      user.data.privateChatRooms = [{id: "222", name: 'bleh', friendId: "abc123", visible: true}]
      user.startPrivateChat "123", "name", "def567", (err, res) ->
        assert.deepEqual(user.data.privateChatRooms, [
          {id: "222", name: 'bleh', friendId: "abc123", visible: true}
          {id: "123", name: 'name', friendId: "def567", visible: true}
        ])
        done()

  describe "closeChat", ->
    it "Should set the chat visibility to false", (done) ->
      user.data.privateChatRooms = [{id: '444', name: 'hey', friendId: 'oijsad', visible: true}]
      user.closeChat "444", (err, user) ->
        assert.deepEqual(user.data.privateChatRooms, [{id: '444', name: 'hey', friendId: 'oijsad', visible: false}])
        done()

  describe "hasAccess", ->
    it "Should return false for a public role user having registered access", ->
      user.data.role = "temp"
      assert.equal(user.hasAccess('registered'), false)

    it "Should return false for a temp role user having registered access", ->
      user.data.role = "temp"
      assert.equal(user.hasAccess('registered'), false)

    it "Should return true for a user role user having registered access", ->
      user.data.role = "user"
      assert.equal(user.hasAccess('registered'), true)

  describe "getInfo", ->
    beforeEach ->
      user.data = {username: "User 53", sanitizedUsername: "user53", password: "hashyhere", salt: "mew", email: "tim@test.com"}

    it "Should not return hash or salt in the data", ->
      info = user.getInfo()
      console.log("Info is: ", info)
      assert !info.password?, "Doesn't have password"
      assert !info.salt?, "Doesn't have a salt"

    it "Should have email in the data", ->
      info = user.getInfo()
      assert.equal info.email, "tim@test.com"

    it "Should have username but not have sanitizedUsername in the data", ->
      info = user.getInfo()
      assert.equal info.username, "User 53"
      assert !info.sanitizedUsername?



  describe "createTempUser", ->
    beforeEach ->
      User.getNextUserId = (callback) -> callback(null, userId)

    it "Should create a user and send them to the callback", (done) ->
      User.createTempUser "temp", (err, user) ->
        assert user?
        assert user.data.id?
        assert user.data.username?
        assert user.data.role?
        done()

    it "Should call save with the user", (done) ->
      insertArgs = null
      User.createTempUser "temp", (err, user) ->
        assert user.data.id?
        done()

  describe "createOauthUser", ->
    provider = "reddit"
    providerId = "r_12345"
    email = "email"
    beforeEach ->
      User.getNextUserId = (callback) -> callback(null, userId)
      User.prototype.save = (callback) -> callback(null, @)
      User.prototype.saveSocialLogin = (provider, providerId, callback) -> callback(null, {})

    it "Should create a user with id, username, email and role", (done) ->
      User.createOauthUser provider, providerId, email, (err, user) ->
        assert user?
        assert user.data.id?
        assert user.data.username?
        assert user.data.role?
        done()

    it "Should save a social login for the user", (done) ->
      saveSocialLoginArgs = null
      User.prototype.saveSocialLogin = (provider, providerId, callback) ->
        saveSocialLoginArgs = arguments
        callback(null, {})

      User.createOauthUser provider, providerId, email, (err, user) ->
        assert saveSocialLoginArgs?
        assert.equal saveSocialLoginArgs[0], provider
        assert.equal saveSocialLoginArgs[1], providerId
        done()

  describe "findOrCreateOAuthUser", ->
    it "Should try and find by provider id", (done) ->
      User.findByProviderId = (provider, providerid, callback) ->
        callback(null, {name: "Mew"})
      User.findOrCreateOauthUser null, null, null, (err, user) ->
        assert.equal user.name, "Mew"
        done()

    it "Should create a user if it can't find by provider id", (done) ->
      User.findByProviderId = (provider, providerid, callback) ->
        callback(null, null)
      User.createOauthUser = (provider, providerId, email, callback)  ->
        callback(null, {name: "CreatedUser"})
      User.findOrCreateOauthUser null, null, null, (err, user) ->
        assert.equal user.name, "CreatedUser"
        done()





  describe "getNextUserId", ->

  describe "findById", ->

  describe "findByUsername", ->
    it "Should call dbHelpers.findByField with relevant info", ->


  describe "findByEmail", ->

  describe "findByProviderId", ->
    beforeEach  ->
      user.getSocialLoginDBId = -> "g_423235"
      User.findById = (id, callback) -> callback(user)
    #
    it "Should callback null if provider or providerId are null", ->
      User.findByProviderId null, "123", (err, user) ->
        assert err
        assert !user?
      User.findByProviderId "google", null, (err, user) ->
        assert err
        assert !user?

    it "Should search for them by getSocialLoginDBId", (done) ->
      getArgs = null
      User.socialLoginTable.get = ->
        getArgs = arguments
        return User.socialLoginTable
      User.findByProviderId "google", "423235", (err, user) ->
        assert getArgs?
        assert.equal getArgs[0], "g_423235"
        done()


  describe "delete", ->

  describe "sanitizeUsername", ->
    it "Should change name to all lowercase and remove spaces", ->
      username = "Abc 1BB"
      assert.equal User.sanitizeUsername(username), 'abc1bb'

  describe "changes", ->
    it "Should return error if the id is null or undefined", (done) ->
      User.changes undefined, (err, user) ->
        assert err?
        done()


