Player = require("./player.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")
maps = require("config/maps")

class PlayerManager

  constructor: (dispatcher)->
    @reset()
    @bindDispatcher(dispatcher)

  begin: () ->

  reset: () ->
    @players = {}
    @mapId = null
    @totalPlayers = 0
    @player = null
    @mainPlayerId = 0
    @dispatcher = null

  bindDispatcher: (dispatcher) ->
    @dispatcher = dispatcher
    @dispatcher.on gameMsg.setPlayers, (data) =>
      @setPlayers(data);
    @dispatcher.on gameMsg.setMainPlayerId, (id) =>
      @mainPlayerId = id;
      if @players[id]?
        @setMainPlayer id;
    @dispatcher.on gameMsg.getPlayer, (playerId, callback) =>
      callback(@getPlayer(playerId))
    @dispatcher.on gameMsg.getMainPlayer, (callback) =>
      callback(@player)
    @dispatcher.on gameMsg.getPlayers, (callback) =>
      callback(@players)
    @dispatcher.on gameMsg.createPlayer, (playerId, callback) =>
      player = @createPlayer(playerId)
      @players[playerId] = player
      callback(player)
    @dispatcher.on gameMsg.gameDetailChanged, (name, value) =>
      if name == "mapId"
        @mapId = value

  getPlayer: (id) ->
    if @players[id]
      return @players[id]
    return null

  getPlayers: ->
    return @players

  getMainPlayer: ->
    return @player

  getTotalPlayersOnTeam: (team) ->
    totalPlayers = 0
    for key, player of @players
      if player.team == team
        totalPlayers++
    return totalPlayers

  getRacesOnTeam: (players, team) ->
    races = []
    for key, player of players
      if player.team == team
        races.push(player.getRace().id)
    return races;

  createPlayer: (id) ->
    startingStats = @getPlayerStartingStats()
    player = new Player(id, startingStats)
    return player;
    
  getPlayerStartingStats: () ->
    map = maps[@mapId];
    startingStats = _.extend({}, config.player.defaultStartingStats, map.startingStats)
    return startingStats;

  setPlayers: (players) ->
    for player in players
      @totalPlayers++
      @players[player.id] = @createPlayer(player.id)
      @players[player.id].setName player.name
      @players[player.id].setRace player.race
      @players[player.id].setAvailableMinions player.minions
      playerTeam = player.team
      if ts.game.settings.mode == config.modes.survival
        playerTeam = 0
      @players[player.id].setTeam playerTeam
    if @mainPlayerId && @players[@mainPlayerId]
      @setMainPlayer @mainPlayerId

  setMainPlayer: (id) ->
    if @players[id]?
      @player = @players[id]
      @player.setIsMainPlayer(true);

  getSnapshot: ->
    snapShot = {}
    if @players?
      for own key, p of @players
        snapShot[p.id] = p.getSnapshot()
    return snapShot


  update: ->
    ts.log.debug("In playerManager update")
    if @players?
      for own key, p of @players
        p.update();

module.exports = PlayerManager
