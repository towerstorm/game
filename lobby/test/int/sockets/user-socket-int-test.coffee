app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require 'assert'
helpers = require '../helpers'
_ = require 'lodash'
socketIO = require('socket.io').listen(14001)
socketIO.set('log level', 1);
GlobalSocket = require('../../../sockets/global-socket.coffee')
globalSocket = new GlobalSocket(socketIO)
UserSocket = require('../../../sockets/user-socket.coffee')
userSocket = new UserSocket(socketIO)
cio = require('socket.io-client')
xhr = require('socket.io-client/node_modules/xmlhttprequest');
xhrOriginal = require('xmlhttprequest');
tdb = require('database')
User = tdb.models.User
db = tdb.db
cookie = require('cookie')
cookieParser = require('cookie-parser')
connect = require('connect')
#request = require('request');

socketIO.on 'connect', (socket) ->
  console.log("Person connected")

socketUrl = 'http://0.0.0.0:14001/sockets/user'

options = {
  transports: ['websocket']
  'force new connection': true
}

cookies = ""
userInfo = null

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
describe "User Socket integration test", ->
  beforeEach (done)->
    #Create a temp user for this person and use there cookies in the connection
    request.get("/auth/temp?username=bot&password=bot")
    .end (err, res) ->
      if err then return done(err)
      userInfo = JSON.parse(res.text)
      cookies = res.headers['set-cookie'].pop().split(';')[0]
      done()

  it "It should allow users to connect", (done) ->
    socket = cio.connect(socketUrl, options)
    socket.on 'error', (err) ->
      done(new Error("Failed to connect, error is: " + err.message))
    socket.on 'connect', ->
      done()

  it "Should send new user details when user changes happen", (done) ->
    socket = cio.connect(socketUrl, options)
    socket.on 'connect', ->
      User.findById userInfo.id, (err, user) ->
        user.set('elo', 1000)
        user.save()
    socket.on 'user.details', (details) ->
      if details.elo == 1000
        done()

  it "Should not crash if the user does not exist for whatever reason", (done) ->
    User.delete userInfo.id, (err, details) ->
      if err then return done(err)
      socket = cio.connect(socketUrl, options)
      socket.on 'connect', ->
        _.defer ->
          done()
        , 2000

  it "Should not crash if the users session has been deleted", (done) ->
    parsedCookie = cookie.parse(cookies)
    sessionId = cookieParser.signedCookie(parsedCookie['express.sid'], '908j0q3wr89j(Unhdaq9ra9s8)(J09jsdfjaqawr')
    tdb.sessionStore.destroy sessionId, (err, dead) ->
      if err then return done(err)
      socket = cio.connect(socketUrl, options)
      socket.on 'connect', ->
        _.defer ->
          done()
        , 2000

  it "Should not crash if there is a db connection error with User.changes", (done) ->
    done() #Don't know how to test this yet as I have no idea what could cause this to fail. Will see when errors log out.

























