log = require('logger')
tdb = require("database")
Lobby = require '../models/lobby'
Queuer = tdb.models.Queuer
User = tdb.models.User
MatchMaker = require '../services/match-maker'
async = require 'async'

LobbyController = {
  ###
    Creates a new lobby room, then gives the id to the user
  ###
  create: (req, res, next) ->
    log.info("User " + req.user.id + " creating lobby")
    startTime = Date.now();
    User.findById req.user.id, (err, user) ->
      Lobby.create req.user.id, user.get('username'), (err, lobby) ->
        if err then return next(err)
        lobby.set('public', true)
        if req.param('public') == 'false'
          lobby.set('public', false)
        lobby.save()
        lobbyId = lobby.get('id')
        log.timing('lobby.lobby.create', Date.now() - startTime);
        log.increment('lobby.lobby.activeLobbies');
        res.status(200).jsonp({id: lobbyId})
        
  join: (req, res, next) ->
    lobbyId = req.param('id')
    log.info("User " + req.user.id + " joining lobby " + lobbyId)
    startTime = Date.now();
    Lobby.findById lobbyId, (err, lobby) ->
      if err then return next({uMsg: "Could not find lobby", err})
      if !lobby.get('public') then return res.status(200).jsonp({error: "This lobby is not public"})
      User.findById req.user.id, (err, user) ->
        if err then return next({uMsg: "User does not exist", err})
        lobby.addUser user.get('id'), user.get('username'), (err, details) ->
          log.timing('lobby.lobby.join', Date.now() - startTime);
          res.status(200).jsonp(lobby.getInfo())

  quit: (req, res, next) ->
    log.info("User " + req.user.id + " leaving lobby " + req.param('id'))
    startTime = Date.now();
    Lobby.findById req.param('id'), (err, lobby) ->
      if err then return next({uMsg: "Could not find lobby", err})
      if lobby.isHost(req.user.id)
        lobby.destroy (err, lobby) ->
          if err then return next(err)
          log.timing('lobby.lobby.quit', Date.now() - startTime);
          log.decrement('lobby.lobby.activeLobbies');
          res.status(200).jsonp({success: true})
      else
        lobby.quit req.user.id, (err, lobby) ->
          if err then return next(err)
          log.timing('lobby.lobby.quit', Date.now() - startTime);
          res.status(200).jsonp({success: true})

  ###
    Outputs JSON of all lobby info if the player is in the lobby
  ###
  info: (req, res, next) ->
    userId = req.user.id
    log.debug("User " + userId + " getting lobby info for lobby " + req.param('id'))
    startTime = Date.now();
    Lobby.findById req.param('id'), (err, lobby) ->
      if err then return next(err)
      if !lobby.isInLobby(userId)
        return next({uMsg: "You are not in this lobby", err})
      log.timing('lobby.lobby.info', Date.now() - startTime);
      res.jsonp(lobby.getInfo())

  ###
    Invites a user to a lobby
  ###
  invite: (req, res, next) ->
    log.info("User " + req.user.id + " inviting user " + req.param('userId') + " to lobby " + req.param('id'))
    startTime = Date.now();
    Lobby.findById req.param('id'), (err, lobby) ->
      if err then return next({uMsg: "Could not find lobby", err})
      if !lobby.isHost(req.user.id)
        return next({uMsg: "You are not the host of this lobby", err})
      User.findById req.param('userId'), (err, user) ->
        if err then return next({uMsg: "User does not exist", err})
        async.parallel [
          (done) ->
            lobby.inviteUser(user.get('id'), done)
          (done) ->
            User.findById req.user.id, (err, hostUser) ->
              user.addLobbyInvitation(lobby.get('id'), hostUser.get('username'), done)
        ], (err, results) ->
          if err then return next(err)
          log.timing('lobby.lobby.invite', Date.now() - startTime);
          res.status(200).jsonp(results[0].getInfo())

  ###
    User accepted invitation to join lobby
  ###
  acceptInvitation: (req, res, next) ->
    lobbyId = req.param('id')
    log.info("User " + req.user.id + " accepting invitation to lobby " + lobbyId)
    startTime = Date.now();
    Lobby.findById req.param('id'), (err, lobby) ->
      if err then return next({uMsg: "Could not find lobby", err})
      User.findById req.user.id, (err, user) ->
        if err then return next({uMsg: "User does not exist", err})
        async.parallel [
          (done) -> lobby.acceptInvitation(user.get('id'), user.get('username'), done)
          (done) -> user.acceptLobbyInvitation(lobby.get('id'), done)
        ], (err, results) ->
          if err then return next(err)
          log.timing('lobby.lobby.acceptInvitation', Date.now() - startTime);
          res.status(200).jsonp(results[0].getInfo())


  ###
    User declined invitation to join lobby
  ###
  declineInvitation: (req, res, next) ->
    lobbyId = req.param('id')
    log.info("User " + req.user.id + " declining invitation to lobby " + lobbyId)
    startTime = Date.now();
    Lobby.findById lobbyId, (err, lobby) ->
      if err then return next({uMsg: "Could not find lobby", err})
      User.findById req.user.id, (err, user) ->
        if err then return next({uMsg: "User does not exist", err})
        async.parallel [
          (done) -> lobby.declineInvitation(user.get('id'), done)
          (done) -> user.declineLobbyInvitation(lobbyId, done)
        ], (err, results) ->
          if err then return next(err)
          log.timing('lobby.lobby.declineInvitation', Date.now() - startTime);
          res.status(200).jsonp(results[0].getInfo())

  queue: (req, res, next) ->
    log.info("User " + req.user.id + " queueing lobby " + req.param('id'))
    startTime = Date.now();
    Lobby.findById req.param('id'), (err, lobby) ->
      if err then return next({uMsg: "Could not find lobby", err})
      if !lobby.isHost(req.user.id)
        return next({uMsg: "You are not the host of this lobby", err})
      Queuer.create lobby.getPlayerIds(), (err, queuer) ->
        if err then return next(err)
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          if err then log.error("Matchmaker checkEnoughPlayersForMatch returned error: ", err.message)
        lobby.queue queuer.get('id'), (err, lobby) ->
          if err then return next(err)
          log.timing('lobby.lobby.queue', Date.now() - startTime);
          log.decrement('lobby.lobby.activeLobbies');
          res.status(200).jsonp(lobby.getInfo())

}

module.exports = LobbyController
