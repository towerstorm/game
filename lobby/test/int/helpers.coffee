app = require('../../lib/app.coffee')
request = require("supertest")(app)
_ = require 'lodash'
querystring = require 'querystring'
tdb = require('database')
User = tdb.models.User

helpers =
  createTempUser: (callback) ->
    userData = {username: 'temp', password: '2'}
    cookies = null
    req = request.get('/auth/temp')
    req.send(userData)
    .expect('Content-Type', /json/)
    .expect(200).end (err, res) ->
      if err then return callback(err)
      cookies = res.headers['set-cookie'].pop().split(';')[0];
      userInfo = JSON.parse(res.text)
      userInfo = _.merge(userInfo, {cookies})
      callback(null, userInfo)

  createRegisteredUser: (callback) ->
    @createTempUser (err, userInfo) ->
      if err then return callback(err)
      User.findById userInfo.id, (err, user) ->
        if err then return callback(err)
        user.set('role', 'user')
        user.save (err, result) ->
          if err then return callback(err)
          return callback(null, userInfo)


  getUserInfo: (userCookies, callback) ->
    req = request.get('/user/')
    req.cookies = userCookies
    req.expect(200).end (err, res) ->
      if err then return callback(err)
      userInfo = JSON.parse(res.text)
      return callback(null, userInfo)

  addFriend: (userInfo, friendInfo, callback) ->
    req = request.get('/user/friends/add/' + friendInfo.username)
    req.cookies = userInfo.cookies
    req.expect(200).end (err, res) ->
      if err then return callback(err)
      req = request.get('/user/friends/accept/' + userInfo.id)
      req.cookies = friendInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return callback(err)
        callback(null, true)

  createLobby: (hostCookies, params, callback) ->
    if arguments.length == 2
      callback = params
      params = {}
    req = request.get('/lobby/create/?' + querystring.stringify(params))
    req.cookies = hostCookies
    req.expect(200)
    .end (err, res) ->
      if err then return callback(err)
      lobbyInfo = JSON.parse(res.text)
      return callback(null, lobbyInfo)

  createQueuer: (hostCookies, params, callback) ->
    if arguments.length == 2
      callback = params
      params = {}
    req = request.get('/lobby/create/?' + querystring.stringify(params))
    req.cookies = hostCookies
    req.expect(200)
    .end (err, res) ->
      if err then return callback(err)
      lobbyInfo = JSON.parse(res.text)
      return callback(null, lobbyInfo)







module.exports = helpers