log = require('logger')
tdb = require('database')
User = tdb.models.User
_ = require 'lodash'
uuid = require 'node-uuid'
async = require 'async'

ChatController =
  createPrivate: (req, res, next) ->
    log.info("Creating private chat")
    startTime = Date.now();
    User.findById req.user.id, (err, user) ->
      if err then return next(err)
      friendId = req.param('userId')
      if !user.hasFriend(friendId)
        return next(new Error("That person is not your friend"))
      chatRoom = user.findPrivateChat(friendId)
      if chatRoom
        user.openChat chatRoom.id, (err, updatedUser) =>
          chatRoom = updatedUser.findPrivateChat(friendId)
          res.jsonp(chatRoom)
      else
        User.findById friendId, (err, friend) ->
          if err then return next(new Error("Could not find friend"))
          chatRoomId = uuid.v4()
          asyncTasks = []
          asyncTasks.push (done) => user.startPrivateChat(chatRoomId, friend.get('username'), friend.get('id'), done)
          asyncTasks.push (done) => friend.startPrivateChat(chatRoomId, user.get('username'), user.get('id'), done)
          async.parallel asyncTasks, (err, result) ->
            if err then return next(err)
            log.timing('lobby.chat.createPrivate', Date.now() - startTime);
            res.jsonp({id: chatRoomId, name: friend.get('username')})

  close: (req, res) ->
    startTime = Date.now();
    User.findById req.user.id, (err, user) ->
      if err then return res.status(200).jsonp({error: 'Not logged in'})
      user.closeChat req.param('chatId'), (err, user) ->
        if err then return next(err)
        log.timing('lobby.chat.close', Date.now() - startTime);
        return res.status(200).jsonp({success: true})



module.exports = ChatController
