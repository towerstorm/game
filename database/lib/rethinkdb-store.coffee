
#!
# * Connect RethinkDB
# * MIT Licensed
# 
db = require("./rethinkdb-client.coffee")
noop = ->

module.exports = (connect) ->
  Store = connect.session.Store
  options = null

  class RethinkStore extends Store
    constructor: (opts) ->
      options = opts or {}
      options.table = options.table or "session"
      options.clientOptions = options.clientOptions or {}
      Store.call this, options # Inherit from Store
      @emit "connect"
      @browserSessionsMaxAge = options.browserSessionsMaxAge or 86400000 # 1 day
      @table = options.table or "session"
      setInterval (->
        @purge()
      ).bind(this), options.flushOldSessIntvl or 60000


    get: (sid, fn) ->
      db.onConnect (err, conn) ->
        return fn(err)  if err
        db.table(options.table).get(sid).run conn, (err, data) ->
          conn.close()
          return fn(err)  if err
          sess = (if data then JSON.parse(data.session) else null)
          fn null, sess

    set: (sid, sess, fn) ->
      sessionToStore =
        id: sid
        expires: (new Date()).getTime() + (sess.cookie.originalMaxAge or @browserSessionsMaxAge)
        session: JSON.stringify(sess)

      db.onConnect (err, conn) ->
        return fn(err)  if err
        db.table(options.table).insert(sessionToStore,
          conflict: "update"
        ).run conn, (err, data) ->
          conn.close()
          return fn(err)  if err
          fn()

    destroy: (sid, fn) ->
      db.onConnect (err, conn) ->
        db.table(options.table).get(sid).delete().run conn, (err, result) ->
          conn.close()
          return fn(err)  if err
          fn()

    purge: (fn) ->
      fn = fn or noop
      now = Date.now()
      db.onConnect (err, conn) ->
        return false  if err
        db.table(options.table).between(0, now, {index: 'expires'}).delete().run conn, (err, data) ->
          conn.close()
          return fn(err)  if err
          fn()

  return RethinkStore

