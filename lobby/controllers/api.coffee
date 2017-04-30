_ = require('lodash')
tdb = require('database')
db = tdb.db
User = tdb.models.User

ApiController = {
  stats: (req, res, next) ->
    db.onConnect (err, conn) ->
      if err then return next(err)
      User.table.getAll('user', {index: 'role'}).count().run conn, (err, total) ->
        conn.close()
        if err then return next(err)
        res.status(200).jsonp({totalRegisteredPlayers: total})

  leaderboard: (req, res, next) ->
    usersPerPage = 50
    offset = parseInt(req.param('page', 0)) * usersPerPage
    db.onConnect (err, conn) ->
      if err then return next(err)
      User.table
      .getAll('user', {index: 'role'})
      .orderBy(db.desc('elo'))
      .skip(offset)
      .limit(usersPerPage)
      .run conn, (err, users) ->
        conn.close()
        if err then return next(new Error("Could not retrieve high scores"))
        usersFiltered = users.map((u, idx) -> _.merge({position: idx + offset + 1}, _.pick(u, ['username', 'elo', 'wins', 'losses'])))
        res.status(200).jsonp(usersFiltered)



}

module.exports = ApiController