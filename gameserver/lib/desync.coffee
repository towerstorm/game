fs = require 'fs'

if process.env.NODE_ENV == "development"
  desyncLogFolder = './logs/desyncs/'
else
  desyncLogFolder = __dirname + '/../../logs/desyncs/'

module.exports = {
  log: (code, tick, userId, gameState, callback) ->
    fileName = desyncLogFolder + code + "." + tick + "." + userId + "." + Date.now() + ".txt"
    fileContents = JSON.stringify(gameState, null, 4); #Set it to have spacing of 4
    console.log "Writing desync to file", fileName
    fs.writeFile fileName, fileContents, callback
}