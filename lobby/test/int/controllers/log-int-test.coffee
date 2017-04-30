app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require('assert')

describe "Log Integration Test", ->
  it "Should return 200 status code", (done) ->
    request.get('/log/error?message=test')
    .expect(200)
    .end (err, result) ->
      if err then return done(err)
      done()


