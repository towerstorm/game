assert = require 'assert'
sinon = require 'sinon'
tdb = require 'database'
db = tdb.db




###
  This is for experimenting with complex rethinkdb queries
###
describe "RethinkDB Unit tests", ->
  queuers = null
  beforeEach (done) ->
    queuers = [
      {id: 1, userIds: [1, 2, 3], state: 'searching'}
      {id: 2, userIds: [4, 5], state: 'searching'}
      {id: 3, userIds: [6], state: 'searching'}
      {id: 4,userIds: [7, 8, 9], state: 'searching'}
      {id: 5,userIds: [10], state: 'searching'}
      {id: 6,userIds: [11, 12, 13], state: 'searching'}
      {id: 7,userIds: [14, 15], state: 'searching'}
    ]
    db.onConnect (err, conn) ->
      db.table('queuers').insert(queuers).run conn, (err, results) ->
        conn.close()
        if err then return done(err)
        done()

  afterEach (done) ->
    db.onConnect (err, conn) ->
      db.table('queuers').between(1,8).delete().run conn, (err, results) ->
        conn.close()
        if err then return done(err)
        done()


  it "Should filter on count of userIds", (done) ->
    db.onConnect (err, conn) ->
      db.expr(queuers)
      .filter(db.row('userIds').count().eq(3))
      .run conn, (err, cursor) ->
        if err then return done(err)
        cursor.toArray (err, results) ->
          conn.close()
          assert.equal results.length, 3
          done()

  it "Should limit after filter", (done) ->
    db.onConnect (err, conn) ->
      db.expr(queuers)
      .filter(db.row('userIds').count().eq(3))
      .limit(2)
      .run conn, (err, cursor) ->
        if err then return done(err)
        cursor.toArray (err, results) ->
          conn.close()
          assert.equal results.length, 2
          done()

  it "Should update 2 items state to found after update", (done) ->
    db.onConnect (err, conn) ->
      db.table('queuers')
      .getAll('searching', {index: 'state'})
      .filter(db.row('userIds').count().eq(3))
      .limit(2)
      .update({state: "found"})
      .run conn, (err, result) ->
        conn.close()
        if err then return done(err)
        assert.equal(result.replaced, 2)
        done()


