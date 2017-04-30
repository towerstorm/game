Lobby = require '../../../models/lobby'
assert = require 'assert'

delay = (ms, func) -> setTimeout(func, ms)

describe "Lobby Model integration test", ->
  lobbyId = null
  beforeEach (done) ->
    Lobby.create 'abc', 'def', (err, lobby) ->
      if err then return done(err)
      lobbyId = lobby.get('id')
      done()
      
  describe "changes", ->
    it "Should not send a change if this lobby did not change", ->


  describe "closeChangesConnection", ->
    it "Should not send any more changes after the connection has closed", (done) ->
      changedLobby = null
      connectionId = Lobby.changes lobbyId, (err, newLobby) ->
        if err && (!err.message || !err.message.match(/closed/))
          return done(err)
        changedLobby = newLobby
      delay 500, -> #Wait for original connection to go through before closing
        Lobby.closeChangesConnection(connectionId)
        delay 500, -> #Wait for close to go through
          Lobby.findById lobbyId, (err, lobby) ->
            if err then return done(err)
            lobby.set('hostUserId', 'aosdj')
            lobby.save ->
              delay 1000, ->
                assert.equal changedLobby, null
                done()



