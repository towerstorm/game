validator = require('validator')
tdb = require('database')
Game = tdb.models.Game

###
  Gets all parameters passed, validates they exist then returns an array
  of them in order which also contains all of them as object fields as well.
###

GameController =
  findByState: (req, res, next) ->
    state = req.param('state', null)
    if !state?
      return res.jsonp({error: "State is a required param"})
    Game.findByState state, (err, games) =>
      if err then return next(err)
      allGames = games.map((game) -> game.data)
      res.jsonp(allGames)











module.exports = GameController