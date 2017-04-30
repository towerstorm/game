Queuer = require '../../../models/queuer.coffee'
assert = require 'assert'
helpers = require '../helpers.coffee'
uuid = require 'node-uuid'

delay = (ms, func) -> setTimeout(func, ms)

describe "Queuer Model Integration test", ->
  queuerId = null
  beforeEach (done) ->
    Queuer.create ['abc'], (err, queuer) ->
      if err then return done(err)
      queuerId = queuer.get('id')
      done()

  describe "accept", ->
    it "Should append the userId to confirmedUserIds and return the queuer", (done) ->
      Queuer.findById queuerId, (err, queuer) ->
        queuer.accept 'abc', (err, queuer) ->
          assert.deepEqual queuer.get('confirmedUserIds'), ['abc']
          done()

    it "Should append two userIds if two people accept", (done) ->
      Queuer.findById queuerId, (err, queuer) ->
        queuer.accept 'abc', (err, queuer) ->
          queuer.accept 'def', (err, queuer) ->
            assert.deepEqual queuer.get('confirmedUserIds'), ['abc', 'def']
            done()

    it "Should not add the same user to confirmedUserIds twice", (done) ->
      Queuer.findById queuerId, (err, queuer) ->
        queuer.accept '123', (err, queuer) ->
          queuer.accept '123', (err, res) ->
            assert(err)
            Queuer.findById queuerId, (err, queuer) ->
              assert.deepEqual queuer.get('confirmedUserIds'), ['123']
              done()

  describe "decline", ->
    it "Should set the queuer's state to declined and return the queuer", (done) ->
      Queuer.decline queuerId, (err, queuer) ->
        assert.deepEqual queuer.get('state'), Queuer.STATES.declined
        done()

  describe "updateStateByMatchId", ->
    it "Should set the queuer of that matchId's state to the state", (done) ->
      matchId = uuid.v4()
      Queuer.findById queuerId, (err, queuer) ->
        queuer.set('matchId', matchId)
        queuer.save (err, queuer) ->
          Queuer.updateStateByMatchId matchId, Queuer.STATES.confirming, (err, result) ->
            Queuer.findById queuerId, (err, queuer) ->
              assert.equal queuer.get('state'), Queuer.STATES.confirming
              done()

  describe "changes", ->
    it "Should get a change notification every time something is modified", (done) ->
      Queuer.changes queuerId, (err, newQueuer) ->
        if err then return done(err)
        assert.equal newQueuer.get('elo'), 1337
        done()
      Queuer.findById queuerId, (err, queuer) ->
        if err then return done(err)
        queuer.set('elo', 1337)
        queuer.save()

    it "Should not send out a change if nothing in the queuer changed", (done) ->
      changedQueuer = null
      Queuer.changes queuerId, (err, newQueuer) ->
        if err then return done(err)
        console.log("Change happened")
        changedQueuer = newQueuer
      Queuer.findById queuerId, (err, queuer) ->
        if err then return done(err)
        queuer.set('elo', queuer.get('elo'))
        queuer.save ->
          setTimeout ->
            assert.equal changedQueuer, null
            done()
          , 1000

    it "Should not send out a change if an array in the queuer changed to the same thing", (done) ->
      changedQueuer = null
      Queuer.changes queuerId, (err, newQueuer) ->
        if err then return done(err)
        console.log("Change happened")
        changedQueuer = newQueuer
      Queuer.findById queuerId, (err, queuer) ->
        if err then return done(err)
        queuer.set('userIds', ['abc'])
        queuer.save ->
          setTimeout ->
            assert.equal changedQueuer, null
            done()
          , 1000

    it "Should not send out a change if another queuer changed", (done) ->
      changedQueuer = null
      Queuer.changes queuerId, (err, newQueuer) ->
        if err then return done(err)
        changedQueuer = newQueuer
      Queuer.create ['asdo'], (err, queuer) ->
        if err then return done(err)
        setTimeout ->
          assert.equal changedQueuer, null
          done()
        , 100

  describe "closeChangesConnection", ->
    it "Should not send any more changes after the connection has closed", (done) ->
      changedQueuer = null
      connectionId = Queuer.changes queuerId, (err, newQueuer) ->
        if err && (!err.message || !err.message.match(/closed/))
          return done(err)
        changedQueuer = newQueuer
      delay 500, -> #Wait for original connection to go through before closing
        Queuer.closeChangesConnection(connectionId)
        delay 500, -> #Wait for close to go through
          Queuer.findById queuerId, (err, queuer) ->
            if err then return done(err)
            queuer.set('elo', 1337)
            queuer.save ->
              delay 1000, ->
                assert.equal changedQueuer, null
                done()





