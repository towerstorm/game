tdb = require("database")
MatchMaker = require ('../services/match-maker')
Queuer = tdb.models.Queuer
Lobby = require('../models/lobby')
log = require('logger')

QueueController = {

  info: (req, res, next) ->
    log.debug("User " + req.user.id + " getting info for queue " + req.param('id'))
    startTime = Date.now();
    Queuer.findById req.param('id'), (err, queuer) ->
      if err then return next({uMsg: "Could not find queuerId", err})
      if !queuer.isInQueuer(req.user.id)
        return next(new Error("You are not in this queue"))
      log.timing('lobby.queue.info', Date.now() - startTime);
      res.status(200).jsonp(queuer.getInfo())

  accept: (req, res, next) ->
    queuerId = req.param('id')
    log.info("User " + req.user.id + " accepting queue " + queuerId)
    startTime = Date.now();
    Queuer.findById queuerId, (err, queuer) ->
      if err then return next({uMsg: "Could not find queuerId", err})
      if !queuer.isInQueuer(req.user.id)
        return next({uMsg: "You are not in this queue", err})
      if !queuer.get('matchId')
        log.error("Queuer tried to accept without being in a match. ", {queuer: queuer.data})
        return next({uMsg: "You are not currently queuing for a match"})
      queuer.accept req.user.id, (err, queuer) ->
        if err then return res.status(200).jsonp({error: err.message})
        MatchMaker.acceptReceived queuer.get('matchId'), (err, details) ->
          if err then return next({uMsg: "Could not accept match request ", err})
          log.timing('lobby.queue.accept', Date.now() - startTime);
          res.status(200).jsonp(queuer.getInfo())

  decline: (req, res, next) ->
    queuerId = req.param('id')
    log.info("User " + req.user.id + " declining queue " + queuerId)
    startTime = Date.now();
    Queuer.findById req.param('id'), (err, queuer) ->
      if err then return next({uMsg: "Could not find queuerId", err})
      if !queuer.isInQueuer(req.user.id)
        return next({uMsg: "You are not in this queue", err})
      if !queuer.get('matchId')
        return next({uMsg: "You are not currently queuing for a match"})
      Queuer.decline queuerId, (err, queuer) ->
        if err then return next({uMsg: "Could not decline match", err})
        Lobby.findByQueuerId queuer.get('id'), (err, lobby) ->
          if err
            log.error("Lobby.findByQueuerId returned error: " + err.message)
          else
            lobby.set('queuerId', null)
            lobby.save()
        MatchMaker.declineReceived queuer.get('matchId'), (err, details) ->
          if err then return next({uMsg: "Something broke", err})
          log.timing('lobby.queue.decline', Date.now() - startTime);
          res.status(200).jsonp(queuer.getInfo())

}

module.exports = QueueController
