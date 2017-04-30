###
  Tests that all the hosts in netconfig are contactable
###

assert = require 'assert'
netconfig = require 'config/netconfig.coffee'
request = require 'request'
ping = require 'ping'

describe "Config Acceptance Test", ->
  it "Should be able to ping the botmanager (" + netconfig.bot.host + ")", (done) ->
    ping.sys.probe netconfig.bot.host, (alive) ->
      assert.equal alive, true, "Can ping " + netconfig.bot.host
      done()

  it "Should be able to ping the gameserver (" + netconfig.gs.host + ")", (done) ->
    ping.sys.probe netconfig.gs.host, (alive) ->
      assert.equal alive, true, "Can ping " + netconfig.gs.host
      done()

  it "Should be able to ping the lobby (" + netconfig.lobby.host + ")", (done) ->
    ping.sys.probe netconfig.lobby.host, (alive) ->
      assert.equal alive, true, "Can ping " + netconfig.lobby.host
      done()
