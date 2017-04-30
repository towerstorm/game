
fs = require 'fs'


cors = (req, res, next) ->
  allowedOrigins = ['http://local.towerstorm.com:7000', 'http://staging.towerstorm.com', 'http://game.towerstorm.com']
  if req.headers.origin in allowedOrigins
    res.header('Access-Control-Allow-Origin', req.headers.origin)
    res.header('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS');
    res.header('Access-Control-Allow-Headers', 'Content-Type,Cookie,Set-Cookie');
    res.header('Access-Control-Allow-Credentials', 'true');
  next();

routes = (app) ->
  controllers = []
  fs.readdir __dirname+'/controllers', (err, list) ->
    if err then throw err
    for file in list 
      Controller = require(__dirname+'/controllers/'+file)
      controllers[file.replace('\.coffee', '')] = new Controller(app)

    app.get '/', controllers.index.index
    app.get '/health', controllers.index.health
    app.get '/user', controllers.index.user
    app.get '/metrics', controllers.index.metrics

    app.get '/game/create', controllers.game.create
    app.get '/game/:code', controllers.game.index
    app.get '/game/join/:code', controllers.game.join_
    app.all '/game/desync/:code', cors
    app.post '/game/desync/:code', controllers.game.desync

module.exports = routes