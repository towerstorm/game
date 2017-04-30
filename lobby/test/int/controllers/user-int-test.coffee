app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require 'assert'
_ = require 'lodash'
helpers = require '../helpers'
tdb = require('database')
db = tdb.db

describe "UserController", ->

  eradicateDb = (callback) ->
    db.onConnect (err, conn) ->
      if err then return callback(err)
      db.table('users').delete().run conn, (err, results) ->
        conn.close()
        return callback(err)

  beforeEach (done) ->
    eradicateDb(done)

  describe "index", ->

  describe "friends", ->

  describe "addFriend", ->
    userInfo = null
    friendInfo = null
    cookies = null
    friendCookies = null
    beforeEach (done) ->
      done()

    it "Should not allow adding of temporary users as friends", (done) ->
      helpers.createRegisteredUser (err, user) ->
        if err then return done(err)
        userInfo = user
        cookies = userInfo.cookies
        helpers.createTempUser (err, user) ->
          if err then return done(err)
          friendInfo = user
          req = request.get('/user/friends/add/' + friendInfo.username)
          req.cookies = userInfo.cookies
          req.expect(200).end (err, res) ->
            if err then return done(err)
            json = JSON.parse(res.text)
            assert json.error
            assert json.error.match(/not registered/)
            done()

  it "Should not allow adding of friends when you're a temporary user", (done) ->
    helpers.createTempUser (err, user) ->
      if err then return done(err)
      userInfo = user
      cookies = userInfo.cookies
      helpers.createRegisteredUser (err, user) ->
        if err then return done(err)
        friendInfo = user
        req = request.get('/user/friends/add/' + friendInfo.username)
        req.cookies = userInfo.cookies
        req.expect(200).end (err, res) ->
          if err then return done(err)
          json = JSON.parse(res.text)
          assert json.error
          assert json.error.match(/You must be registered/)
          done()

  it "Should allow adding of registered users when you're registered", (done) ->
      helpers.createRegisteredUser (err, user) ->
        if err then return done(err)
        userInfo = user
        cookies = userInfo.cookies
        helpers.createRegisteredUser (err, user) ->
          if err then return done(err)
          friendInfo = user
          req = request.get('/user/friends/add/' + friendInfo.username)
          req.cookies = userInfo.cookies
          req.expect(200).end (err, res) ->
            if err then return done(err)
            json = JSON.parse(res.text)
            assert !json.error
            done()



  describe "acceptFriend", ->

  describe "declineFriend", ->

  describe "updateUsername", ->
    username = null
    beforeEach ->
      username = "personyea"

    it "Should not change the users username if they are a temp user", (done) ->
      helpers.createTempUser (err, userInfo) ->
        cookies = userInfo.cookies
        if err then return done(err)
        req = request.get('/user/update/username/' + username)
        req.cookies = cookies
        req.expect(200).end (err, res) ->
          if err then return done(err)
          console.log("Res is: ", res.text)
          response = JSON.parse(res.text)
          assert.equal(response.error, "You must be registered to set your username")
          done()



