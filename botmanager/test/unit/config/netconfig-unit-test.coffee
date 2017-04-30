assert = require 'assert'
netconfig = require 'config/netconfig'

describe "netconfig", ->
  it "Should return url of host + port for each site", ->
    assert.equal netconfig.lobby.url, "http://" + netconfig.lobby.host + ":" + netconfig.lobby.port
