assert = require 'assert'
sinon = require 'sinon'
_ = require 'lodash'
db = require '../../../lib/rethinkdb-client.coffee'

describe "Rethinkdb Client Integration Test", ->
  it "Should be able to get a fake db connection", (done) ->
    sinon.stub(db, 'connect').callsArgWith(1, null, "CONNECTION")
    db.onConnect (err, connection) ->
      assert.equal connection, "CONNECTION"
      db.connect.restore()
      done()

  it "Should be able to get a real DB connection", (done) ->
    db.onConnect (err, connection) ->
      assert !err?, "No error returned"
      assert connection, "Got connection"
      assert.equal connection.db, "towerstorm"
      done()
