Controller = require __dirname+'/base'
config = require 'config/gameserver'
fs = require "fs"
uuid = require 'node-uuid'
netconfig = require 'config/netconfig'
log = require('logger')
Game = require '../models/game'
metrics = require('../lib/metrics')

class GameController extends Controller

  constructor: () ->

  index: (req, res) =>
    log.info("Calling index")
    gamePackageInfo = require "game/package.json"
    code = req.param "code", null
    if !code
      return res.status(500).send("No Code param passed")

    Game.findByCode code, (err, game) =>
      if err
        res.write "Game doesn't exist"
        return res.end();

      templateVariables =
        code: code
        nodeEnv: process.env.NODE_ENV
        gameVersion: gamePackageInfo.version
        serverVersion: process.env.VERSION

      if game.state == config.states.lobby
        res.render "gamelobby", templateVariables

      else if game.state == config.states.begun || game.state == config.states.started
        res.render "game", templateVariables
      else
        res.write "Game is finished or not begun"
        res.end();

  getUserId: (user, callback) =>
    if user?
      callback(null, user.id)
    else
      callback("No user", null)

  join_: (req, res) =>
    log.info("Calling join game")
    code = req.param "code", null
    if !code?
      res.status(500).jsonp({error: "No code specified"});
    else
      res.redirect("/game/"+code);

  create: (req, res) =>
    log.info("Calling create game");
    startTime = Date.now();
    if req.user?
      userId = req.user.id

    Game.create (err, game) =>
      if err then return res.status(500).jsonp({error: "Failed to create game.", details: err})
      if !game then return res.status(500).jsonp({error: "Failed to create game. without error."})

      game.hostId = userId
      game.matchId = req.param('matchId', null)
      log.info("Setting game details", {hostId: game.hostId, matchId: game.matchId})
      initStartTime = Date.now();
      game.init (err, success) =>
        if err then return res.status(500).jsonp({error: err.message})
        log.timing('gameserver.game.init', Date.now() - initStartTime);
        if req.param('mode')
          game.setMode(req.param('mode'))

        ### This is so we can connect to games with an ip address (localally hosted) ###
        server = netconfig.gs.externalHost
        log.info("Game init complete, sending details to client", {server: server, code: game.get('code')})
        log.timing('gameserver.game.create', Date.now() - startTime);
        res.status(200).jsonp({server: server, code: game.get('code')})


  desync: (req, res) =>
    code = req.param("code", null)
    tick = req.body.tick
    gameSnapshot = req.body.gameSnapshot
    log.info("Received Desync notification")
    startTime = Date.now();
    if !code || !tick || !gameSnapshot
      log.info("code, tick or gameSnapshot are missing from the desync")
      return res.status(500).jsonp({error: "code, tick and gameSnapshot are required"})
    log.info("Desync info: code: " + code + " tick: " + tick)
    @getUserId req.user, (err, userId) =>
      if err
        log.info("Could not find user: ", req.user)
        userId = "user"
      require('../lib/desync').log code, tick, userId, gameSnapshot, (err, data) ->
        log.timing('gameserver.game.desync', Date.now() - startTime);
        res.status(200).jsonp({success: true})





module.exports = GameController