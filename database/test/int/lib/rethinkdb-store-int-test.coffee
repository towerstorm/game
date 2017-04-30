assert = require 'assert'
netconfig = require('config/netconfig')

mockConnect = {
  session: {}
}

class Store
  emit: ->
mockConnect.session.Store = Store

RDBStore = require('../../../lib/rethinkdb-store')(mockConnect)
sessionStore = null

describe "RethinkDB Store test", ->
  beforeEach ->

    sessionStore = new RDBStore({
      flushOldSessIntvl: 60000,
      table: 'sessions',
      clientOptions: {
        db: 'towerstorm'
        host: netconfig.db.host
        port: netconfig.db.port
        authKey: netconfig.db.authKey
      }
    })

  it "Should be able to call set", (done) ->
    sessionStore.set 123, {cookie: 'mew!'}, ->
      assert true
      done()

  it "Should be able to call get", (done) ->
    sessionStore.get 123, ->
      assert true
      done()

  it "Should be able to call destroy", (done) ->
    sessionStore.destroy 123, ->
      assert true
      done()

  it "Should be able to call purge", (done) ->
    sessionStore.purge ->
      assert true
      done()
