assert = require 'assert'
sinon = require 'sinon'
_ = require 'lodash'
tdb = require('database')
db = tdb.db
MatchMaker = require('../../../services/match-maker.coffee')
Queuer = tdb.models.Queuer
nock = require 'nock'
netconfig = require 'config/netconfig'
config = require 'config/lobby'
uuid = require 'node-uuid'

describe "Matchmaker Integration Test", ->
  exisitingQueuers = []
  populateDb = (callback) ->
    _.map(exisitingQueuers, (val, idx) -> val.id = idx + 1) #Add id to each item so they can be cleaned up easily, +1 to start at 1
    db.onConnect (err, conn) ->
      db.table('queuers').insert(exisitingQueuers).run conn, (err, results) ->
        conn.close()
        if err then return callback(err)
        callback()

  eradicateDb = (callback) ->
    db.onConnect (err, conn) ->
      db.table('queuers').delete().run conn, (err, results) ->
        conn.close()
        if err then return callback(err)
        callback()

  beforeEach (done) ->
    config.matchConfirmTime = 0
    eradicateDb(done)

  describe "checkEnoughPlayersForMatch", ->
    beforeEach ->
      sinon.stub(MatchMaker, 'confirmPlayers').callsArgWith(1, null, true)
      sinon.stub(MatchMaker, 'resumeSearching').callsArgWith(1, null, true)

    afterEach ->
      MatchMaker.confirmPlayers.restore()
      MatchMaker.resumeSearching.restore()

    it "Should call confirmPlayers when there are 2 groups of 3 in the queue", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], state: 'searching'}
        {userIds: [4, 5, 6], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [4, 5, 6]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          assert(MatchMaker.confirmPlayers.calledOnce)
          done()

    it "Should set each players state to the matchId instead of searching", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], state: 'searching'}
        {userIds: [4, 5, 6], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [4, 5, 6]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          db.onConnect (err, conn) =>
            db.table('queuers').between(1, 3).run conn, (err, cursor) ->
              if err then return done(err)
              cursor.toArray (err, queuers) ->
                conn.close()
                for queuer in queuers
                  assert(queuer.state != 'searching')
                done()



    it "Should call resumeSearching when there is only one group of 3 in the queue", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [1, 2, 3]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          assert(MatchMaker.resumeSearching.calledOnce)
          done()

    it "Should set each players state to matchId even when there isn't enough (they are reverted later)", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [1, 2, 3]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          db.onConnect (err, conn) =>
            db.table('queuers').between(1, 3).run conn, (err, cursor) ->
              if err then return done(err)
              cursor.toArray (err, queuers) ->
                conn.close()
                for queuer in queuers
                  assert(queuer.state != 'searching')
                done()

    it "Should call confirmPlayers when there are 6 solo players in the queue", (done) ->
      exisitingQueuers = [
        {userIds: [1], state: 'searching'}
        {userIds: [2], state: 'searching'}
        {userIds: [3], state: 'searching'}
        {userIds: [4], state: 'searching'}
        {userIds: [5], state: 'searching'}
        {userIds: [6], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [6]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          assert(MatchMaker.confirmPlayers.calledOnce)
          done()

    it "Should call resumeSearching when there are 5 solo players in the queue", (done) ->
      exisitingQueuers = [
        {userIds: [1], state: 'searching'}
        {userIds: [2], state: 'searching'}
        {userIds: [3], state: 'searching'}
        {userIds: [4], state: 'searching'}
        {userIds: [5], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [5]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          assert(MatchMaker.resumeSearching.calledOnce)
          done()

    it "Should call confirmPlayers when there are 2 groups of 2 and 2 solo players in the queue", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2], state: 'searching'}
        {userIds: [3, 4], state: 'searching'}
        {userIds: [5], state: 'searching'}
        {userIds: [6], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [3, 4]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          assert(MatchMaker.confirmPlayers.calledOnce)
          done()

    it "Should call resumeSearching when there are 2 groups of 2 and 1 solo player in the queue", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2], state: 'searching'}
        {userIds: [3, 4], state: 'searching'}
        {userIds: [5], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [3, 4]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          assert(MatchMaker.resumeSearching.calledOnce)
          done()

  describe "confirmPlayers", ->
    matchId = null
    beforeEach (done) ->
      matchId = uuid.v4()
      exisitingQueuers = [
        {userIds: [1, 2, 3], state: 'searching', matchId: matchId}
        {userIds: [4, 5, 6], state: 'searching', matchId: matchId}
      ]
      populateDb (err) ->
        if err then return done(err)
        done()

    it "Should set all players states to confirming", (done) ->
      sinon.stub(MatchMaker, 'checkPlayersAreConfirmed').callsArgWith(1, null, true)
      MatchMaker.confirmPlayers matchId, (err, details) ->
        console.log("DONE1")
        Queuer.findAllByMatchId matchId, (err, queuers) ->
          console.log("DONE2")
          queuers.forEach (queuer) ->
            assert.equal(queuer.get('state'), Queuer.STATES.confirming)
          MatchMaker.checkPlayersAreConfirmed.restore()
          done()

    it "Should call checkPlayersAreConfirmed after matchConfirmTime", (done) ->
      config.matchConfirmTime = 100
      sinon.stub MatchMaker, 'checkPlayersAreConfirmed', ->
        assert(MatchMaker.checkPlayersAreConfirmed.calledWith(matchId))
        MatchMaker.checkPlayersAreConfirmed.restore()
        done()
      MatchMaker.confirmPlayers matchId, (err, details) ->
        assert(MatchMaker.checkPlayersAreConfirmed.notCalled)

  describe "checkPlayersAreConfirmed", ->
    matchId = null
    beforeEach ->
      matchId = uuid.v4()

    describe "Game with unconfirmed", ->
      beforeEach (done) ->
        sinon.stub(MatchMaker, 'sendToGame').callsArgWith(1, null, true)
        sinon.stub(MatchMaker, 'resumeSearching').callsArgWith(1, null, true)

        exisitingQueuers = [
          {userIds: [1, 2], confirmedUserIds: [1], state: 'searching', matchId: matchId}
          {userIds: [3, 4], confirmedUserIds: [3, 4], state: 'searching', matchId: matchId}
          {userIds: [5], confirmedUserIds: [5], state: 'searching', matchId: matchId}
          {userIds: [6], confirmedUserIds: [], state: 'searching', matchId: matchId}
        ]
        populateDb (err) ->
          if err then return done(err)
          Queuer.findAll (err, queuers) ->
            done()

      afterEach ->
        MatchMaker.sendToGame.restore()
        MatchMaker.resumeSearching.restore()

      it "Should set every queuer that hasn't fully checked in to state of declined", (done) ->
        MatchMaker.checkPlayersAreConfirmed matchId, (err, details) ->
          if err then return done(err)
          Queuer.findAll (err, queuers) ->
            if err then return done(err)
            queuers = queuers.map((q) -> q.data).map((d) -> {userIds: d.userIds, confirmedUserIds: d.confirmedUserIds, state: d.state, matchId: d.matchId});
            queuers = _.sortBy(queuers, (q) -> q.userIds[0])
            expectedQueuers = [
              {userIds: [1, 2], confirmedUserIds: [], state: 'declined', matchId: null}
              {userIds: [3, 4], confirmedUserIds: [3, 4], state: 'searching', matchId: matchId}
              {userIds: [5], confirmedUserIds: [5], state: 'searching', matchId: matchId}
              {userIds: [6], confirmedUserIds: [], state: 'declined', matchId: null}
            ]
            assert.deepEqual(queuers, expectedQueuers)
            done()

      it "Should call resumeSearching with the other queuers", (done) ->
        MatchMaker.checkPlayersAreConfirmed matchId, (err, details) ->
          if err then return done(err)
          assert(MatchMaker.resumeSearching.calledWith(matchId))
          done()

    describe "Game without unconfirmed", ->
      beforeEach (done) ->
        sinon.stub(MatchMaker, 'sendToGame').callsArgWith(1, null, true)
        sinon.stub(MatchMaker, 'resumeSearching').callsArgWith(1, null, true)

        exisitingQueuers = [
          {userIds: [1, 2], confirmedUserIds: [1, 2], state: 'searching', matchId: matchId}
          {userIds: [3, 4], confirmedUserIds: [3, 4], state: 'searching', matchId: matchId}
          {userIds: [5], confirmedUserIds: [5], state: 'searching', matchId: matchId}
          {userIds: [6], confirmedUserIds: [6], state: 'searching', matchId: matchId}
        ]
        populateDb (err) ->
          if err then return done(err)
          Queuer.findAll (err, queuers) ->
            done()

      afterEach ->
        MatchMaker.sendToGame.restore()
        MatchMaker.resumeSearching.restore()

      it "Should call sendToGame if there are no unconfirmedQueuers in this match", (done) ->
        MatchMaker.checkPlayersAreConfirmed matchId, (err, details) ->
          if err then return done(err)
          assert(MatchMaker.sendToGame.calledWith(matchId))
          done()

  describe "acceptReceived", ->
    matchId = null
    beforeEach ->
      sinon.stub(MatchMaker, 'sendToGame').callsArgWith(1, null, true)
      matchId = uuid.v4()

    afterEach ->
      MatchMaker.sendToGame.restore()

    it "Should send all players to the game if all players are confirmed", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], confirmedUserIds: [1, 2, 3], state: 'searching', matchId: matchId}
        {userIds: [4, 5, 6], confirmedUserIds: [4, 5, 6], state: 'searching', matchId: matchId}
      ]
      populateDb (err) ->
        if err then return done(err)
        MatchMaker.acceptReceived matchId, (err, details) ->
          if err then return done(err)
          assert(MatchMaker.sendToGame.calledOnce)
          done()

    it "Should not send aany players to the game if not players are confirmed", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], confirmedUserIds: [1, 2, 3], state: 'searching', matchId: matchId}
        {userIds: [4, 5, 6], confirmedUserIds: [5, 6], state: 'searching', matchId: matchId}
      ]
      populateDb (err) ->
        if err then return done(err)
        MatchMaker.acceptReceived matchId, (err, details) ->
          if err then return done(err)
          assert(MatchMaker.sendToGame.notCalled)
          done()


  describe "declineReceived", ->
    it "Should return all other queuers to searching", (done) ->
      matchId = uuid.v4()
      exisitingQueuers = [
        {userIds: [1, 2], confirmedUserIds: [], state: 'confirming', matchId: matchId}
        {userIds: [3, 4], confirmedUserIds: [3, 4], state: 'confirming', matchId: matchId}
        {userIds: [5], confirmedUserIds: [5], state: 'confirming', matchId: matchId}
        {userIds: [6], confirmedUserIds: [], state: 'declined', matchId: null}
      ]
      populateDb (err) ->
        if err then return done(err)
        MatchMaker.declineReceived matchId, (err, details) ->
          if err then return done(err)
          Queuer.findAll (err, queuers) ->
            if err then return done(err)
            queuers = queuers.map((q) -> q.data).map((d) -> {userIds: d.userIds, confirmedUserIds: d.confirmedUserIds, state: d.state, matchId: d.matchId});
            queuers = _.sortBy(queuers, (q) -> q.userIds[0])
            expectedQueuers = [
              {userIds: [1, 2], confirmedUserIds: [], state: 'searching', matchId: null}
              {userIds: [3, 4], confirmedUserIds: [], state: 'searching', matchId: null}
              {userIds: [5], confirmedUserIds: [], state: 'searching', matchId: null}
              {userIds: [6], confirmedUserIds: [], state: 'declined', matchId: null}
            ]
            assert.deepEqual(queuers, expectedQueuers)
            done()



  describe "createGame", ->
    beforeEach ->
      sinon.stub(MatchMaker, 'confirmPlayers', (matchId, callback) -> callback(null, {matchId}))
      nock(netconfig.gs.url).filteringPath(/matchId=[a-f0-9-]*/g, 'matchId=XXX').get('/game/create?matchId=XXX').reply(200, {server: 'gs-1.0-8-833', code: 'JxYr' })

    afterEach ->
      MatchMaker.confirmPlayers.restore()

    it "Should set all queuers in this match's game to the game details but not change their state to found yet", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], state: 'searching'}
        {userIds: [4, 5, 6], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [4, 5, 6]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          if err then return done(err)
          MatchMaker.createGame details.matchId, (err, details) ->
            if err then return done(err)
            db.onConnect (err, conn) =>
              db.table('queuers').between(1, 3).run conn, (err, cursor) ->
                if err
                  conn.close()
                  return done(err)
                cursor.toArray (err, queuers) ->
                  conn.close()
                  assert.equal(queuers.length, 2)
                  for queuer in queuers
                    assert.equal(queuer.state, 'waiting')
                    assert.equal(queuer.game.code, 'JxYr')
                    assert.equal(queuer.game.server, 'gs-1.0-8-833')
                  done()

  describe "sendToGame", ->
    beforeEach ->
      sinon.stub(MatchMaker, 'confirmPlayers', (matchId, callback) -> callback(null, {matchId}))

    afterEach ->
      MatchMaker.confirmPlayers.restore()

    it "Should set all queuers in this match's state to found", (done) ->
      exisitingQueuers = [
        {userIds: [1, 2, 3], state: 'searching'}
        {userIds: [4, 5, 6], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [4, 5, 6]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          if err then return done(err)
          MatchMaker.sendToGame details.matchId, (err, details) ->
            if err then return done(err)
            db.onConnect (err, conn) =>
              db.table('queuers').between(1, 3).run conn, (err, cursor) ->
                if err
                  conn.close()
                  return done(err)
                cursor.toArray (err, queuers) ->
                  conn.close()
                  assert.equal(queuers.length, 2)
                  for queuer in queuers
                    assert.equal(queuer.state, 'found')
                  done()

  describe "resumeSearching", ->
    it "Should set all queuers in this match back to searching", (done) ->
      exisitingQueuers = [
        {userIds: [1], state: 'searching'}
        {userIds: [2], state: 'searching'}
        {userIds: [3], state: 'searching'}
        {userIds: [4], state: 'searching'}
        {userIds: [5], state: 'searching'}
      ]
      populateDb (err) ->
        if err then return done(err)
        queuer = {get: -> [1]}
        MatchMaker.checkEnoughPlayersForMatch queuer, (err, details) ->
          db.onConnect (err, conn) =>
            db.table('queuers').between(1, 6).run conn, (err, cursor) ->
              if err
                conn.close()
                return done(err)
              cursor.toArray (err, queuers) ->
                conn.close()
                assert.equal(queuers.length, 5)
                for queuer in queuers
                  assert.equal(queuer.state, 'searching')
                done()




















