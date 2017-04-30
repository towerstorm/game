assert = require 'assert'
sinon = require 'sinon'
_ = require 'lodash'
db = require '../../../lib/rethinkdb-client.coffee'


describe "RethinkDB Client Unit Test", ->
  describe "_getConnection", ->
    it "Should log as an error if it's not a handshake error", (done) ->
      if db.connect.restore
        db.connect.restore()
      sinon.stub(db, 'connect').callsArgWith(1, new Error("Other error"))
      sinon.stub(db.log, 'error')
      db._getConnection ->
        assert db.log.error.calledOnce
        db.log.error.restore()
        db.connect.restore()
        done()

    it "Should log as a warning if error is a handshake error", (done) ->
      if db.connect.restore
        db.connect.restore()
      sinon.stub(db, 'connect').callsArgWith(1, new Error("Handshake error"))
      sinon.stub(db.log, 'warn')
      db._getConnection ->
        assert db.log.warn.calledOnce
        db.log.warn.restore()
        db.connect.restore()
        done()

  describe "onConnect", ->
    it "Should call getConnection once when attempts of 1 is passed", (done) ->
      sinon.stub(db, '_getConnection').callsArgWith(0, new Error("Handshake error"))
      db.onConnect 1, ->
        assert.equal db._getConnection.callCount, 1
        db._getConnection.restore()
        done()

    it "Should retry 10 times if the attempts argument is omitted", (done) ->
      sinon.stub(db, '_getConnection').callsArgWith(0, new Error("Handshake error"))
      db.onConnect ->
        assert.equal db._getConnection.callCount, 10
        db._getConnection.restore()
        done()


