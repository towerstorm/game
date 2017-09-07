log = require('logger')
config = require('config/botmanager')
gameMsg = require('config/game-messages')
bulkLoad = require("config/bulk-load")
towers = bulkLoad("towers");
minions = bulkLoad("minions");
maps = bulkLoad("maps");
races = bulkLoad("races");
_ = require 'lodash'

noop = ->
###
 * The Game keeps track of the Tower Storm game instance and has helper 
 functions for stuff like what the bots current health is etc. 

 It also has it's own dispatcher that it uses to send messages about what's
 happening in the game so that other components can keep track of how many 
 towers actually built or minions got sent. 
###
class Game
  initialized: false
  dispatcher: null
  gameId: null
  gameOver: false
  playerId: null
  initPlayer: null #Player details at the start of the game for if we need them before we get a snapshot
  lastTotalTowers: 0
  mapId: null
  currentTick: null

  #Init does all the constructing so it can be unit tested
  constructor: (@dispatcher) ->
    return @

  init: (code) ->
    if @initialized
      return false
    @initialized = true
    log.info("Initializing game code: " + code)
    @dispatcher.on config.messages.gameBeginning, (details) =>
      @mapId = details.settings.mapId
    return @

  setPlayerDetails: (details) ->
    @playerId = details.id
    @initPlayer = {
      id: details.id
      race: details.race
      minions: details.minions
      team: details.team
    }

  end: ->
    @gameOver = true

  getCurrentTick: ->
    return @currentTick

  ###
  Takes tick data from the server and sends it through to our local
  copy of the game. 
  ###
  processTickData: (tick, data, callback = noop) ->
    @currentTick = tick
    #Send the data for this tick to our local game
    _.defer =>
      #Broadcast to other modules whenever one of our towers has successfully built
      if data.towers?
        for tower in data.towers
          # log.info "In process tick data got tower of: ", tower
          @dispatcher.emit config.messages.towerCreated, tower.xPos, tower.yPos, tower.ownerId, tower.towerType
      callback()

  ###
    Sends out a message for each gem on the battlefield that the bot should collect
  ###
  processGemDrops: () ->
                
  getPlayer: () ->
    return @initPlayer

  getPlayerId: () ->
    return @playerId

  getHealth: () ->
    player = @getPlayer()
    if player?
      return player.health;
    return null;

  getGold: () ->
    player = @getPlayer()
    if player?
      return player.gold;
    return null;

  getTeam: () ->
    player = @getPlayer()
    if player?
      return player.team;
    return null;

  getRace: () ->
    player = @getPlayer()
    if player?
      return player.race;
    return null;

  getAvailableMinions: () ->
    player = @getPlayer()
    if player?
      return player.minions;
    return null;

  getMapId: () ->
    return @mapId
    
  getMapInfo: () ->
    return maps[@mapId]


  getTimePassed: () ->
    @getCurrentTick() / config.gameTickRate

  ###
    TODO: Implement cost and stuff
  ###
  canSendMinion: (minionType) ->
    availableMinions = @getAvailableMinions()
    return availableMinions.indexOf(minionType) >= 0

  ###
    TODO: Implement cost and stuff
  ###
  canPickTower: (towerType) ->
    raceInfo = races[@getRace()]
    return raceInfo.towers.indexOf(towerType) >= 0

module.exports = Game




