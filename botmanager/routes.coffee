
fs = require 'fs'



routes = (router) ->
  controllers = []
  fs.readdir __dirname+'/controllers', (err, list) ->
    if err then throw err
    for file in list 
      Controller = require(__dirname+'/controllers/'+file)
      controllers[file.replace('\.coffee', '')] = new Controller()

    router.get '/', controllers.index.index

    router.get '/bot/create/:server', controllers.botmanager.createGame
    router.get '/bot/join/:server/:key/:details', controllers.botmanager.joinGame


module.exports = routes