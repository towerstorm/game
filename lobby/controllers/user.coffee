log = require('logger')
tdb = require('database')
User = tdb.models.User

class UserController
  constructor: (@app) ->

  index: (req, res, next) ->
    User.findById req.user.id, (err, user) ->
      if err then return next(err)
      res.jsonp(user.getInfo())

  friends: (req, res, next) ->
    User.findById req.user.id, (err, user) ->
      if err then return next(err)
      res.jsonp(user.get('friends'))

  addFriend: (req, res, next) ->
    if !req.param('username') then return next(new Error("Missing username param"))
    startTime = Date.now();
    User.findByUsername req.param('username'), (err, friend) ->
      if err? || !friend then return next({uMsg: "User not found"})
      if !friend.hasAccess('registered') then return next({uMsg: "That user is not registered. Your friend must register with a social account before you can add them."})
      User.findById req.user.id, (err, user) ->
        if err then return res.send(401);
        if !user.hasAccess('registered') then return next({uMsg: "You must be registered to add friends."})
        user.requestFriendship friend.get('id'), (err, data) ->
          if err? then return next(err)
          log.timing('lobby.user.addFriend', Date.now() - startTime);
          res.jsonp({success: true})

  acceptFriend: (req, res, next) ->
    if !req.param('friendId') then return next(new Error("Missing friendId param"))
    startTime = Date.now();
    User.findById req.user.id, (err, user) ->
      if err then return res.send(401);
      user.acceptFriend req.param('friendId'), (err, data) ->
        if err? then return next(err)
        log.timing('lobby.user.acceptFriend', Date.now() - startTime);
        res.jsonp({success: true})


  declineFriend: (req, res, next) ->
    if !req.param('friendId') then return next(new Error("Missing friendId param"))
    startTime = Date.now();
    User.findById req.user.id, (err, user) ->
      if err then return res.send(401);
      user.declineFriend req.param('friendId'), (err, data) ->
        if err? then return next(err)
        log.timing('lobby.user.declineFriend', Date.now() - startTime);
        res.jsonp({success: true})


  updateUsername: (req, res, next) ->
    if !req.param('username') then return next(new Error("Missing username param"))
    startTime = Date.now();
    log.info("User is changing their username to ", req.param('username'))
    User.findById req.user.id, (err, user) ->
      changeUsername = ->
        user.changeUsername req.param('username'), (err, data) ->
          if err
            if err.message? && err.message.charAt(0) == '>'
              return next({uMsg: err.message.substr(1), err})
            else
              return next(err)
          log.timing('lobby.user.updateUsername', Date.now() - startTime);
          res.jsonp({success: true})
      if user.get('role') == "bot" then return changeUsername()
      User.findByUsername req.param('username'), (err, existingUser) ->
        if existingUser then return res.status(200).jsonp({error: "That username has already been taken"})
        return changeUsername()

  search: (req, res, next) ->
    if !req.param('friendId') then return next(new Error("Missing friendId param"))
    startTime = Date.now();
    User.findByUsername req.param('username'), (err, user) ->
      if err || !user?
        return res.send(404, "User not found")
      else
        log.timing('lobby.user.search', Date.now() - startTime);
        res.jsonp(user.id)

  delete: (req, res, next) ->
    User.delete req.user.id, (err, data) ->
      if err? then return next(err)
      res.send(200, data)


module.exports = new UserController()



