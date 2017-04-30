app = require('../../../lib/app.coffee')
request = require("supertest")(app)
_ = require 'lodash'
sinon = require 'sinon'
Game = require('../../../models/game.coffee')
tdb = require 'database'
User = tdb.models.User
assert = require 'assert'
sio = require('socket.io')
cio = require('socket.io-client')
xhr = require('socket.io-client/node_modules/xmlhttprequest');
xhrOriginal = require('xmlhttprequest');
passport = require('passport')
LocalStrategy = require('passport-local').Strategy
rs = require 'randomstring'

delay = (time, func) -> setTimeout(func, time)

options = {
  transports: ['websocket']
  'force new connection': true
}

userInfo = null
cookies = ""
game = null
global.metricsServer

overrideXmlHttpRequest = () ->
  xhr.XMLHttpRequest = ->
    @XMLHttpRequest = xhrOriginal.XMLHttpRequest;
    xhrOriginal.XMLHttpRequest.apply(@, arguments);
    this.setDisableHeaderCheck(true);
    openOriginal = this.open;
    this.open = (method, url, async, user, password) ->
      openOriginal.apply(this, arguments);
      this.setRequestHeader('cookie', cookies);
    return @

overrideXmlHttpRequest()

describe "Game Model Integration Test", ->
  beforeEach ->
    global.io = {
      set: -> true
      of: -> @
      on: -> @
    }

  describe "init", ->
    it "Should be able to initialize a game", (done) ->
      game = new Game()
      game.init ->
        done()

  describe "create", ->
    it "Should be able to create a new game and save it out", (done) ->
      Game.create (err, game) ->
        if err then return done(err)
        game.save (err, result) ->
          if err then return done(err)
          assert result != null
          done()

  describe "socket authorization", ->
    socketUrl = ""
    userId = null
    tempUsername = ""
    before (done) ->
      express = require('express')
      passport.use(new LocalStrategy({}, (username, password, fn) ->
        User.createTempUser username, (err, user) ->
          userId = user.get('id')
          tempUsername = user.get('username')
          fn(err, user.data)
      ))
      router = express.Router()
      router.get('/user/create', passport.authenticate('local'), (req, res) ->
        res.status(200).jsonp({user: req.user})
      )
      app.use(router)
      request = require("supertest")(app)
      global.io = sio.listen(15001)
      global.io.set('log level', 1)
      game = new Game()
      game.init ->
        socketUrl = 'http://0.0.0.0:15001/game/' + game.get('code')
        game.bindSockets()
        request.get("/user/create?username=test" + rs.generate(4) + "&password=pass")
        .end (err, res) ->
          if err then return done(err)
          console.log("Res text is: " + res.text)
          userInfo = JSON.parse(res.text)
          cookies = res.headers['set-cookie'].pop().split(';')[0]
          console.log("Cookies are: " + cookies)
          done()

    it "Should allow users to connect", (done) ->
      socket = cio.connect(socketUrl, options)
      socket.on 'error', (err) ->
        done(new Error("Failed to connect, error is: " + err.message))
      socket.on 'connect', ->
        done()

    it "Should call userConnected with the users id and username", (done) ->
      sinon.stub game, 'userConnected', ->
        assert.equal(arguments[0], userId)
        assert.equal(arguments[1], tempUsername)
        game.userConnected.restore()
        done()
      socket = cio.connect(socketUrl, options)
      socket.on 'error', (err) ->
        done(new Error("Failed to connect, error is: " + err.message))

  describe "begin", ->
    it "Should be able to call game.begin", (done) ->
      game = new Game()
      game.init ->
        game.begin()
        assert true
        done()

  describe "automatic end", ->
    it "Should end if a custom game is going for 10 seconds without anyone connecting", (done) ->
      done()

    it "Should end and send cancelled to players if a matchmaking game is going for 30 seconds without all players connecting", (done) ->
      done()

  describe "end", ->
    xit "Should call when players have reported that the game has ended", (done) ->
      game = new Game()
      game.init ->
        game.addPlayer({id: 'abc'});
        game.begin()
        sinon.stub(game, 'end')
        game.playerFinished('abc', 15, 1);
        delay 200, -> #Wait for game to finish the update loop
          assert game.end.calledWith(1)
          game.end.restore()
          done()

    xit "Should send the last tick of the game to clients", (done) ->
      game = new Game()
      player = null
      finalTick = null
      game.init ->
        player = {
          id: 'ppp'
          socket: {
            emit: -> true
          }
          disconnect: -> true
          sendTick: sinon.stub()
        }
        game.players = [player]
        game.end = ->
          finalTick = game.get('currentTick');
        game.begin()
        delay 200, ->
          game.playerFinished('abc', 15, 1);
          delay 200, -> #Wait for game to finish update loop
            assert(player.sendTick.calledWith(finalTick), "player.sendTick " + finalTick + " actual " + player.sendTick.getCall(0).arguments);
            done()

  describe "tutorial", ->
    it "Should be able to create a tutorial", (done) ->
      game = new Game()
      game.init ->
        game.get('settings').mode = "TUTORIAL"
        done()




