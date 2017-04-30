GameEntity = require("../entities/game-entity.coffee")
Gem = require("../entities/gem.coffee")

gameMsg = require("config/game-messages")

class GemManager
  constructor: (dispatcher) ->
    @reset()
    @bindDispatcher(dispatcher);
    @maxCollectDist = config.tileSize;
    @maxCollectDistSqrd = @maxCollectDist * @maxCollectDist;

  reset: () ->
    @totalGems = 0;
    @gems = [];
    @maxCollectDist = 0;
    @maxCollectDistSqrd = 0;

  bindDispatcher: (dispatcher) ->
    dispatcher.on gameMsg.minionDied, (minion, killer) =>
      if minion?.owner? && killer?
        offset = {x: Math.round(Math.random()*20)-20, y: Math.round(Math.random()*20)-20} #Making them appear kind of randomly instead of all in hte same spot.
        @spawnGem(minion.pos.x, minion.pos.y, minion.minionType, minion.owner.getId(), offset)
    dispatcher.on gameMsg.clickNoSelection, (x, y) =>
      @collectInArea(x, y);
    dispatcher.on gameMsg.gemSuicide, (gem) =>
      @gemSuicide(gem)

  spawnGem: (x, y, minionType, playerId, offset) ->
    gemId = @nextGemId()
    settings = {id: gemId, minionType: minionType, playerId: playerId, offset: offset}
    gem = ts.game.spawnEntity GameEntity.CTYPE.GEM, x, y, settings
    @gems.push(gem)
    ts.game.dispatcher.emit gameMsg.createdGem, gem

  ###
    Called when mouse clicks in an area without a tower selected. Calls collect for instant collection
    then this is confirmed by the server later.
  ###
  collectInArea: (x, y) ->
    player = null
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (p) =>
      player = p
    if !player?
      return false
    for gem, idx in @gems
      if gem.playerId == player.getId()
        dist = ts.game.functions.getDistSqrd(gem.getCenter(), {x: x, y: y});
        if dist < @maxCollectDistSqrd && !gem.collected
          ts.game.dispatcher.emit gameMsg.action.collectGem, gem.id
          gem.collect();
          return true;

  nextGemId: ->
    gemId = @totalGems
    @totalGems++
    return gemId

  ###
    This comes from the server, it tells the game that a gem has been collected and the
    game runs collectConfirm to finalize collection of the gem.
  ###
  collectGem: (id) ->
    for gem, idx in @gems
      if gem.id == id
        gem.collectConfirm();
        @gems.splice(idx, 1)
        return true;
    return false;

  gemSuicide: (gemToDie) ->
    gemToDieId = gemToDie.id
    for gem, idx in @gems
      if gem.id == gemToDieId
        gem.kill();
        @gems.splice(idx, 1)
        return true;

    return false

module.exports = GemManager
