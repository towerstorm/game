app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require 'assert'
_ = require 'lodash'
rs = require 'randomstring'
tdb = require("database")
Game = tdb.models.Game

describe "Game Controller", ->
  params = {version: '0.3.0', serverNum: 1, code: 'XYGQQ', hostUserId: '123'}
  createGame = (code, callback) ->
    sendParams = _.clone(params)
    if arguments.length == 1
      callback = code
    else
      sendParams.code = code
    Game.register sendParams, (err, game) ->
      callback(null, game.get('id'))


  beforeEach ->
    #Delete all games of the code XYGQQ so DB isn't filled with them

  describe "findByState", ->
    gameId = null
    code = 'test_' + rs.generate(8)
    state = 'test_' + rs.generate(8)
    beforeEach (done) ->
      createGame code, (err, id) ->
        gameId = id
        done()

    it "Should find a game by the state passed in", (done) ->
      Game.findById gameId, (err, game) ->
        game.set('state', state)
        game.save (err, game) ->
          if err then return done(err)
          request.get('/game/search/state/' + state)
          .expect(200)
          .end (err, res) ->
              if err then return done(err)
              console.log("Text is: ", res.text)
              returnedGames = JSON.parse(res.text)
              assert.equal returnedGames.length, 1
              assert.equal returnedGames[0].code, code
              done()







