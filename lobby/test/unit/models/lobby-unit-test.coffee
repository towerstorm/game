assert = require 'assert'
sinon = require 'sinon'
_ = require 'lodash'
Lobby = require '../../../models/lobby.coffee'

lobby = null

describe "Lobby Model Unit Test", ->
  beforeEach ->
    lobby = new Lobby()

  describe "changes", ->
    it "Should return error if id is undefined", (done) ->
      Lobby.changes undefined, (err, result) ->
        assert err?
        assert err instanceof Error
        done()
