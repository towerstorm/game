app = require("../../../lib/app.coffee")
request = require("supertest")(app)
assert = require 'assert'
nock = require 'nock'

describe "Botmanager Controller int test", ->
  describe "createGame", ->

  describe "joinGame", ->
    it "Should return 500 error if the bot can't connect to the server", (done) ->
      jsonDetails = JSON.stringify({team: 1})
      request.get("/bot/join/test.com/xxxx/" + jsonDetails)
      .expect(500)
      .end (err, res) ->
        if err then return done(err)
        done()
