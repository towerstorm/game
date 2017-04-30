app = require('../../../lib/app.coffee')
assert = require 'assert'
uuid = require 'node-uuid'
request = require("supertest")(app)
helpers = require '../helpers'
tdb = require('database')
Queuer = tdb.models.Queuer

userInfo = null
queuerInfo = null
describe "Queue Integration Test", ->
  beforeEach (done) ->
    helpers.createTempUser (err, user) ->
      userInfo = user
      Queuer.create [userInfo.id], (err, queuer) ->
        queuer.set('matchId', uuid.v4())
        queuer.save (err, queuer) ->
          queuerInfo = queuer.getInfo()
          done()

  describe "info", ->
    it "Should return an error if the queuer is not found", ->

    it "Should return an error if the user is not in this queuer", ->

    it "Should return into about the queuer if all is good", ->

  describe "accept", ->
    it "Should add userId to the confirmedUserIds list", (done) ->
      req = request.get('/queue/' + queuerInfo.id + '/accept')
      req.cookies = userInfo.cookies
      req.expect(200)
      .end (err, res) ->
        if err then return done(err)
        console.log("res is: " + res.text)
        info = JSON.parse(res.text)
        assert.deepEqual info.confirmedUserIds, [userInfo.id]
        done()

  describe "decline", ->
    it "Should set the queuer's state to declined", (done) ->
      req = request.get('/queue/' + queuerInfo.id + '/decline')
      req.cookies = userInfo.cookies
      req.expect(200)
      .end (err, res) ->
        if err then return done(err)
        console.log("res is: " + res.text)
        info = JSON.parse(res.text)
        assert.deepEqual info.state, "declined"
        done()




