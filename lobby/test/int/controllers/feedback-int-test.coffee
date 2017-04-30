app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require 'assert'
_ = require 'lodash'
helpers = require '../helpers'


userInfo = null
describe "Feedback Integration test", ->
  beforeEach (done) ->
    helpers.createTempUser (err, user) ->
      if err then return done(err)
      userInfo = user
      done()

  describe "rating", ->
    it "Should send a rating through mandrill and return 200 code", (done) ->
      req = request.get('/feedback/rating/?rating=7')
      req.cookies = userInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return done(err)
        done()

  describe "comment", ->
    it "Should send a comment through mandrill", (done) ->
      req = request.get('/feedback/comments/?comments=This%20is%20a%20comment')
      req.cookies = userInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return done(err)
        done()

  describe "address", ->
    it "Should send the users name and address through mandrill", (done) ->
      req = request.get('/feedback/address/?name=Test%20Person&address=11%20Test%20Street')
      req.cookies = userInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return done(err)
        done()
