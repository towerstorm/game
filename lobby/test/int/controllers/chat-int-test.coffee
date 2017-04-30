app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require 'assert'
_ = require 'lodash'
helpers = require '../helpers'

userInfo = null
describe "ChatController", ->
  beforeEach (done) ->
    helpers.createRegisteredUser (err, user) ->
      userInfo = user
      done()

  describe "create", ->
    friendInfo = null
    chatInfo = null
    beforeEach (done) ->
      helpers.createRegisteredUser (err, user) ->
        friendInfo = user
        helpers.addFriend userInfo, friendInfo, (err, result) ->
          req = request.get('/chat/create/' + friendInfo.id)
          req.cookies = userInfo.cookies
          req.expect(200).end (err, res) ->
            if err then return done(err)
            chatInfo = JSON.parse(res.text)
            done()

    it "Should create a private chat with the other user", (done) ->
      assert(chatInfo.id)
      assert.equal(chatInfo.name, friendInfo.username)
      done()

    it "Should add room to privateChatRooms on requesting user", (done) ->
      req = request.get('/user/')
      req.cookies = userInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return done(err)
        info = JSON.parse(res.text)
        assert.deepEqual(info.privateChatRooms, [{id: chatInfo.id, name: friendInfo.username, friendId: friendInfo.id, visible: true}]);
        done()

    it "Should add room to privateChatRooms on friend", (done) ->
      req = request.get('/user/')
      req.cookies = friendInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return done(err)
        info = JSON.parse(res.text)
        assert.deepEqual(info.privateChatRooms, [{id: chatInfo.id, name: userInfo.username, friendId: userInfo.id, visible: true}]);
        done()










