config = require 'config/botmanager'
logic = require 'config/bot-logic'
assert = require 'assert'
gameMsg = require 'config/game-messages'
proxyquire = require 'proxyquire'
Brain = proxyquire('../../../../lib/brains/brain', {
  './tower-brain': require '../../mocks/tower-brain-mock'
})
Dispatcher = require '../../../../lib/dispatcher'
_ = require 'lodash'
log = require('logger')

describe "Brain", ->
  brain = null
  game = null
  beforeEach ->
    dispatcher = new Dispatcher();
    dispatcher.reset()
    game =
      dispatcher: dispatcher
    brain = new Brain(game);
    brain.dispatcher = dispatcher

  describe "init", ->
    beforeEach ->
      brain.towerBrain =
        getMapDetails: -> assert true

    it "Should bind the dispatcher to game.dispatcher", ->
      boundDispatcher = false
      brain.bindDispatcher = ->
        boundDispatcher = true
      brain.init();
      assert.equal boundDispatcher, true

  describe "bindDispatcher", ->
    it "Should bind gem creation to gemDropped function", ->
      gemDroppedArgs = null
      brain.gemDropped = ->
        gemDroppedArgs = arguments
      brain.bindDispatcher(game.dispatcher)
      brain.dispatcher.emit config.messages.gemDropped, {test: 5}
      assert gemDroppedArgs?
      assert.deepEqual gemDroppedArgs[0], {test: 5}

  describe "gemDropped", ->
    emitArgs = null

    beforeEach ->
      emitArgs = null
      brain.shouldCollectGem = -> true
      brain.game.getPlayerId = -> "ABC"
      brain.game.getPlayer = -> {}
      brain.dispatcher.emit = ->
        emitArgs = arguments

    it "Should send out a collect message if shouldCollectGem returns true and we are the playerId", ->
      brain.gemDropped({id: 5, playerId: "ABC"})
      assert emitArgs?
      assert.equal emitArgs[0], config.messages.collectGem, 5

    it "Should do nothing if the player is someone else", ->
      brain.gemDropped({id: 5, playerId: "TTT"})
      assert !emitArgs?

    it "Should do nothing if shouldCollectGem returns false", ->
      brain.shouldCollectGem = -> false
      brain.gemDropped({id: 5, playerId: "ABC"})
      assert !emitArgs?

  describe "getChanceToBePatient", ->
    describe "Should return bot patience level * patienceDecayRate for every patient count so far", ->
      it "Patience 1, patienceCount 0", ->
        brain.attributes.patience = 1
        brain.patienceCount = 0
        assert.equal brain.getChanceToBePatient(), 1

      it "Patience 1, patienceCount 1", ->
        brain.attributes.patience = 1
        brain.patienceCount = 1
        assert.equal brain.getChanceToBePatient(), 1 * Math.pow(logic.patienceDecayRate, 1)

      it "Patience 1, patienceCount 2", ->
        brain.attributes.patience = 1
        brain.patienceCount = 2
        assert.equal brain.getChanceToBePatient(), 1 * Math.pow(logic.patienceDecayRate, 2)

      it "Patience 0.5, patienceCount 2", ->
        brain.attributes.patience = 0.5
        brain.patienceCount = 2
        assert.equal brain.getChanceToBePatient(), 0.5 * Math.pow(logic.patienceDecayRate, 2)


  describe "isBeingPatient", ->
    beforeEach ->

    it "Should return true if we are being patient", ->
      brain.patientUntilTime = Date.now() + 5
      assert.equal brain.isBeingPatient(), true

    it "Should increase patienceCount by 1 if we are choosing to be patient", ->
      brain.randomRoll = -> 0.1
      brain.getChanceToBePatient = -> 0.2
      brain.patienceCount = 0
      assert.equal brain.isBeingPatient(), true
      assert.equal brain.patienceCount, 1

    it "Should set patientUntilTime to Date.now() + patienceTime", ->
      brain.randomRoll = -> 0.1
      brain.getChanceToBePatient = -> 0.2
      brain.patientUntilTime = 0
      assert.equal brain.isBeingPatient(), true
      assert.equal Math.round(brain.patientUntilTime / 100), Math.round((Date.now() + logic.patienceTime * 1000) / 100)

    it "Should set patienceCount to zero if we're not being patient", ->
      brain.randomRoll = -> 0.5
      brain.getChanceToBePatient = -> 0.2
      brain.patienceCount = 2
      assert.equal brain.isBeingPatient(), false
      assert.equal brain.patienceCount, 0

  describe "getNextTurn", ->
    beforeEach ->
      brain.game.getGold = -> 500
      brain.getBiasToBuildTowers = -> 0
      brain.determineBestMinionToSend = -> "goblin"
      brain.determineBestTowerToBuild = -> "crossbow"

    it "Should return a turn of {} if a function throws an error", ->
      brain.attributes.aggression = 1
      brain.randomRoll = -> 0.5
      brain.determineBestMinionToSend = ->
        throw new Error("fail")
      assert.deepEqual brain.getNextTurn(), {}

  describe "getBiasToBuildTowers", ->

  describe "getMinTargetSpend", ->

  describe "getMaxTargetSpend", ->

  describe "getSpawnPoint", ->
    beforeEach ->
      brain.game.getMapId = -> 0
      brain.game.getTeam = -> 0

    it "Should throw an error if the map does not exist", ->
      brain.game.getMapId = -> 124234
      assert.throws ->
        brain.getSpawnPoint()

    it "Should throw an error if the map does not have a spawn point for that team", ->
      brain.game.getMapId = -> 0
      brain.game.getTeam = -> 12
      assert.throws ->
        brain.getSpawnPoint()


  describe "determineBestMinionToSend", ->

  describe "getTotalCost", ->
    it "Should return the total of all cost values added up", ->
      minions = [{cost: 5}, {cost: 12}]
      assert.equal brain.getTotalCost(minions), 17

  describe "getRandomMinionWeightedByGold", ->
    it "Should return minion.type of one of the minions in the list", ->
      minions = [{type: 'rabbit', cost: 5}, {type: 'pig', cost: 9}]
      chosenType = brain.getRandomMinionWeightedByGold(minions)
      assert chosenType?, "Chosen tye is not null"
      assert chosenType == 'rabbit' || chosenType == 'pig', "Chosen type is rabbit or pig"




 