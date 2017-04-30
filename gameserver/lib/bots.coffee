request = require 'request'
config = require 'config/gameserver'
netconfig = require 'config/netconfig'
log = require('logger')
async = require('async');

bots =
  add: (gameCode, botDetails, callback) ->
    startTime = Date.now();
    jsonDetails = ""
    try
      jsonDetails = JSON.stringify(botDetails);
    catch error
      return callback("Failed to parse bot details")
    url = netconfig.bot.url + '/bot/join/'+netconfig.bot.host+'/'+gameCode+'/'+jsonDetails
    log.info("Bot connecting to: " + url)
    requestBot = (done) ->
      request {url: url, timeout: config.requestTimeout}, (err, res, body) ->
        if err then return done(err)
        done(null, body)
    async.retry config.maxConnectRetries, requestBot, (err, body) ->
      log.timing('gameServer.bots.add', Date.now() - startTime);
      return callback(err, body);
      
  configure: (bot, details) ->
    if !bot?
      return false
    if !bot.isBot
      return false
    if details.team?
      bot.setTeam details.team
    return true;

module.exports = bots

