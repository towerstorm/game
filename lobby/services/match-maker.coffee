_ = require 'lodash'
tdb = require('database')
db = tdb.db
Lobby = require('../models/lobby')
Queuer = tdb.models.Queuer
User = tdb.models.User
uuid = require("node-uuid")
async = require('async')
request = require("request")
netconfig = require('config/netconfig')
config = require('config/lobby')
log = require('logger')

noop = -> true

Matchmaker = {
  ###
    Matches teams of 3 aagainst other teams of 3, 2 + 1 against 2 + 1 and individuals against individuals
  ###
  checkEnoughPlayersForMatch: (queuer, callback) ->
    log.info("checkEnoughPlayersForMatch being called with queuer: ", queuer.data)
    matchId = uuid.v4()
    totalPlayers = queuer.get('userIds').length

    if totalPlayers in [1, 3]
      db.onConnect (err, conn) =>
        if err then return callback(err)
        Queuer.table
        .getAll(Queuer.STATES.searching, {index: 'state'})
        .filter(db.row('userIds').count().eq(totalPlayers))
        .limit(6 / totalPlayers)
        .update(db.branch(db.row('state').eq(Queuer.STATES.searching), {state: Queuer.STATES.waiting, matchId: matchId}, {}), {returnChanges: true})
        .run conn, (err, result) =>
          conn.close()
          if err then return callback(err)
          log.info("checkEnoughPlayers query done", {matchId, replaced: result.replaced, totalPlayers, changes: result.changes})
          if result.replaced == (6 / totalPlayers) #We need 2 groups of 3 people or 6 people
            @confirmPlayers matchId, (err, details) =>
              if err then return callback(err)
              return callback(null, {matchId})
          else
            @resumeSearching matchId, (err, details) =>
              if err then return callback(err)
              return callback(null, {matchId})

    if totalPlayers == 2
      db.onConnect (err, conn) =>
        if err then return callback(err)
        asyncTasks = []

        #Find 2 rows with 2 players and 2 with 1 player
        asyncTasks.push (done) =>
          Queuer.table
          .getAll(Queuer.STATES.searching, {index: 'state'})
          .filter(db.row('userIds').count().eq(2))
          .limit(2)
          .update(db.branch(db.row('state').eq(Queuer.STATES.searching), {state: Queuer.STATES.waiting, matchId: matchId}, {}), {returnChanges: true})
          .run conn, (err, result) =>
            done(err, result)

        asyncTasks.push (done) =>
          Queuer.table
          .getAll(Queuer.STATES.searching, {index: 'state'})
          .filter(db.row('userIds').count().eq(1))
          .limit(2)
          .update(db.branch(db.row('state').eq(Queuer.STATES.searching), {state: Queuer.STATES.waiting, matchId: matchId}, {}), {returnChanges: true})
          .run conn, (err, result) =>
            done(err, result)

        async.parallel asyncTasks, (err, results) =>
          conn.close()
          if err then return callback(err)
          log.info("checkEnoughPlayers query done", {matchId, replaced0: results[0].replaced, replaced1: results[1].replaced, totalPlayers, changes0: results[0].changes, changes1: results[1].changes})
          if results[0].replaced != 2 || results[1].replaced != 2 #We need 2 2 person queuers and 2 1 person queuers
            @resumeSearching matchId, (err, details) =>
              if err then return callback(err)
              return callback(null, {matchId})
          else
            @confirmPlayers matchId, (err, details) =>
              if err then return callback(err)
              return callback(null, {matchId})

  ###
    Sets state to confirming and all players see a "Match found, accept or decline" screen.
    In xx seconds this checks if players have confirmed and if all have it starts the game
    If all players confirm before 10 seconds it also starts the game.
    All players who decline or don't click accept get removed from the queue.
    Also create the game so it's already created by the time players confirm
  ###
  confirmPlayers: (matchId, callback = noop) ->
    log.info("in confirmPlayers", {matchId})
    @createGame(matchId)
    Queuer.updateStateByMatchId matchId, Queuer.STATES.confirming, (err, result) ->
      if err
        log.error("confirmPLayers updateStateByMatchId failed", {err: err.message, result, matchId})
        return callback(err)
      log.info("confirmPLayers updateStateByMatchId complete", {matchId, result})
      callback(null, true)
    _.delay((=> @checkPlayersAreConfirmed(matchId, ->)), config.matchConfirmTime)

  checkPlayersAreConfirmed: (matchId, callback = noop) ->
    log.info("in checkPlayersAreConfirmed", {matchId})
    db.onConnect (err, conn) =>
      if err
        log.error("checkPlayersAreConfirmed onConnect error: " + err.message)
        return callback(err)
      Queuer.table
      .getAll(matchId, {index: 'matchId'})
      .filter(db.row('userIds').count().gt(db.row('confirmedUserIds').count()))
      .update(db.branch(db.row('matchId').eq(matchId),{state: Queuer.STATES.declined, confirmedUserIds: [], matchId: null},{}), {returnChanges: true})
      .run conn, (err, result) =>
        if err
          log.error("checkPlayerAreConfirmed processing error: " + err.message)
          return callback(err)
        if result.replaced > 0
          log.info("found unconfirmedQueuers: ", _.merge({}, {matchId}, {unconfirmedQueuers: _.map(result.changes, (c) -> c.new_val)}))
          @resumeSearching matchId, (err, details) =>
            if err then return callback(err)
            return callback(null, {matchId})
        else
          log.info("zero unconfirmedQueuers found.", {matchId})
          @sendToGame matchId, (err, details) =>
            if err
              @resumeSearching(matchId)
              return callback(err)
            return callback(null, {matchId})

  ###
    Called after a successful confirmation after the queuer has been updated with the confirmedUserId
    Goes through all queuers in this match and checks if all are confirmed, if all are then it creates the game.
  ###
  acceptReceived: (matchId, callback = noop) ->
    log.info("in acceptReceived", {matchId})
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Queuer.table
      .getAll(matchId, {index: 'matchId'})
      .filter(db.row('userIds').count().gt(db.row('confirmedUserIds').count()))
      .run conn, (err, cursor) =>
        if err
          conn.close()
          return callback(err)
        cursor.toArray (err, unconfirmedQueuers) =>
          conn.close()
          if err then return callback(err)
          if unconfirmedQueuers.length != 0
            totalUnconfirmedPlayers = unconfirmedQueuers.map((uq) -> uq.userIds.length - uq.confirmedUserIds.length).reduce(((l, r) -> l + r), 0)
            confirmedUserIds = unconfirmedQueuers.map((uq) -> uq.confirmedUserIds).reduce(((l, r) -> l.concat(r)), [])
            unconfirmedPlayers = unconfirmedQueuers.map((uq) -> uq.userIds).reduce(((l, r) -> l.concat(r)), []).filter((userId) -> userId not in confirmedUserIds)
            log.info("totalUnconfirmedPlayers is #{totalUnconfirmedPlayers}", {matchId})
            log.info("unconfirmed players are #{unconfirmedPlayers}", {matchId})
            return callback(null, {totalUnconfirmedPlayers})
          log.info("acceptReceived totalUnconfirmedPlayers is 0 so creating game", {matchId})
          @sendToGame matchId, (err, details) =>
            if err
              @resumeSearching(matchId)
              return callback(err)
            return callback(null, {matchId})

  ###
    Set all other players in this match back to searching
  ###
  declineReceived: (matchId, callback = noop) ->
    log.info("in declineReceived", {matchId})
    db.onConnect (err, conn) =>
      if err then return callback(err)
      Queuer.table
      .getAll(matchId, {index: 'matchId'})
      .filter(db.row('state').eq(Queuer.STATES.confirming))
      .update(db.branch(db.row('matchId').eq(matchId),{state: Queuer.STATES.searching, confirmedUserIds: [], matchId: null},{}), {returnChanges: true})
      .run conn, (err, result) =>
        conn.close()
        log.info("declineRecieved done", {matchId, result})
        callback(err, result)


  createGame: (matchId, callback = noop) ->
    log.info("in createGame, connecting to url: " + netconfig.gs.url, {matchId})
    request {url: netconfig.gs.url + '/game/create?matchId=' + matchId, timeout: config.requestTimeout}, (err, res, body) =>
      if err
        log.error("Could not contact game server " + netconfig.gs.url + ", err: " + err.message, {matchId})
        return callback(new Error("Could not contact game server " + netconfig.gs.url + ", err: " + err.message, {matchId}))
      try
        gameDetails = JSON.parse(body)
      catch e
        log.error("Could not parse message from game server: " + body)
        return callback(new Error("Could not parse message from game server: " + body))
      if gameDetails.error then return callback(new Error("Game server returned error: ", gameDetails.error))
      game = {server: gameDetails.server, code: gameDetails.code}
      log.info("created game", {game, matchId})
      Queuer.updateGameByMatchId matchId, game, (err, result) =>
        if err
          log.error("createGame updateGameByMatchId encountered error " + err.message, {matchId})
          return callback(err)
        log.info("createGame updateGameByMatchId done", {matchId, result})
        callback(null, true)

  ###
    Sets all players in this match states to "found" so they join the game that was created previously.
  ###
  sendToGame: (matchId, callback = noop) ->
    log.info("in sendToGame ", {matchId})
    Queuer.updateStateByMatchId matchId, Queuer.STATES.found, (err, result) =>
      if err
        log.error("sendToGame updateStateByMatchId encountered error " + err.message, {matchId})
        return callback(err)
      log.info("sendToGame updateStateByMatchId done", {matchId, result})
      return callback(null, true)

  resumeSearching: (matchId, callback = noop) ->
    log.info("in resumeSearching", {matchId})
    Queuer.resumeSearching matchId, (err, result) =>
      if err
        log.error("resumeSearching encountered error " + err.message, {matchId})
        return callback(err)
      log.info("resumeSearching done", {matchId, result})
      return callback(null, true)

}

module.exports = Matchmaker





