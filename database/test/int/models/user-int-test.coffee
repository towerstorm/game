User = require '../../../models/user'
assert = require 'assert'
rs = require 'randomstring'

delay = (ms, func) -> setTimeout(func, ms)

describe "User Integration Test", ->
  userId = null
  beforeEach (done) ->
    User.create 'abc', 'password', (err, user) ->
      if err then return done(err)
      userId = user.get('id')
      done()

  describe "create / login", ->
    username = "testperson" + rs.generate(4)
    password = "password" + rs.generate(4)

    it "Should be able to login to a user after creating one", (done) ->
      User.create username, password, (err, user) ->
        if err then return done(err)
        User.findByUsernamePassword username, password, (err, user) ->
          if err then return done(err)
          assert(user != null)
          done()
          
  describe "changes", ->
  
  describe "closeChangesConnection", ->
    it "Should not send any more changes after the connection has closed", (done) ->
      changedUser = null
      connectionId = User.changes userId, (err, newUser) ->
        if err && (!err.message || !err.message.match(/closed/))
          return done(err)
        changedUser = newUser
      delay 500, -> #Wait for original connection to go through before closing
        User.closeChangesConnection(connectionId)
        delay 500, -> #Wait for close to go through
          User.findById userId, (err, user) ->
            if err then return done(err)
            user.set('elo', 1337)
            user.save ->
              delay 1000, ->
                assert.equal changedUser, null
                done()




