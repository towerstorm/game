tdb = require('database')
Game = tdb.models.Game
User = tdb.models.User
Queuer = tdb.models.Queuer
log = require('logger')

defaultError = (res) ->
  res.json({error: "An error occured with your request"})

class AdminController
  listGames: (req, res) ->
    Game.findAll (err, games) ->
      if err then return defaultError(res)
      res.json(games.map((game) -> game.data))

  listGame: (req, res) ->
    gameId = req.param("gameId", null)
    Game.findById gameId, (err, game) ->
      if err then return defaultError(res)
      res.json(game.data)

  listQueuers: (req, res) ->
    Queuer.findAll (err, queuers) ->
      if err then log.info("Error occured: ", err)
      if err then return defaultError(res)
      res.json(queuers.map((queuer) -> queuer.data))

  listUsers: (req, res) ->
    User.findAll (err, users) ->
      if err then log.info("Error occured: ", err)
      if err then return defaultError(res)
      res.json(users.map((user) -> user.getInfo()))

module.exports = new AdminController()
