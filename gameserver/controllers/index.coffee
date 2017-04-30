Controller = require __dirname+'/base'
config = require 'config/gameserver'
netconfig = require 'config/netconfig'
db = require('../../database').db
metrics = require('../lib/metrics')
log = require('logger')


class IndexController extends Controller

  constructor: (@app) ->

  index: (req, res) ->
    dbConnection = false
    log.info("Index page being loaded");
    db.onConnect (err, conn) ->
      if !err && conn
        dbConnection = true
        conn.close()

      res.status(200).jsonp({
        server: netconfig.gs.host
        online: true
        dbConnection: dbConnection
      });

  ###
    If average game tick rate is > 50ms then it gives a 500 error
    so that no new games are created on this server.
  ###
  health: (req, res) ->
    activeGames = metrics.activeGames.count;
    if activeGames && activeGames > 2
      log.info("Game server reporting offline as active games is too high", {activeGames})
      res.status(503).send()
      if metrics.lastGameStart && Date.now() - metrics.lastGameStart > (7200 * 1000)
        metrics.activeGames.count = 0
        metrics.lastGameStart = 0
        log.error("Game did not end in 2 hours, restarting server");
        throw new Error("Game did not end in 2 hours, restarting server");
    else
      res.status(200).send()


  metrics: (req, res) ->
    data = {
      activeGames: metrics.activeGames.count
      lastGameStart: metrics.lastGameStart
    };
    res.status(200).jsonp(data);



  user: (req, res) ->
    console.log req.user
    if req.user?
      res.status(200).jsonp(req.user)
    else
      res.status(200).send("No user found. ")




module.exports = IndexController