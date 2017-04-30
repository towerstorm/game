rs = require 'randomstring'
async = require 'async'
Bot = require '../lib/bot'
log = require('logger')

delay = (ms, func) -> setTimeout(func, ms)
nodeEnv = process.env.NODE_ENV || 'development'

class BotManager
  bots: []

  constructor: (@app) ->
    @bots = []

  createGame: (req, res) =>
    server = req.param "server", null
    bot = new Bot();
    bot.init();
    bot.createGame server, (err, data) =>
      if err
        log.error("Bot failed to create game, error is: ", err)
        return res.status(500).json({error: err})
      res.status(200).json(data)
    @bots.push bot  

  joinGame: (req, res) =>
    server = req.param "server", null
    key = req.param "key", null
    detailsJSON = req.param "details", null
    log.info("Bot joining game server: " + server + ", key: " + key + " details: " + detailsJSON)
    details = null
    try
      details = JSON.parse(detailsJSON);
    catch e
      log.error("Couldn't parse bot details: ", detailsJSON)
    log.info("Received bot details of ", details)
    bot = new Bot()
    @bots.push(bot)
    bot.init(details);
    bot.authenticate (err, authDetails) ->
      if err then return res.status(500).send(err)
      log.info("Bot authenticated")
      bot.joinGame server, key, (err, playerDetails) ->
        if err then return res.status(500).send(err)
        log.info("Bot joined game")
        res.status(200).json(playerDetails)

module.exports = BotManager