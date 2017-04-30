app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require 'assert'

describe "Index controller", ->
  it "Should respond with details about it's environment", (done) ->
    request.get('/')
    .expect(200)
    .end (err, res) ->
      if err then return done(err)
      responseObject = JSON.parse(res.text)
      assert responseObject.server
      assert.equal responseObject.online, true
      assert.equal responseObject.dbConnection, true
      done()


