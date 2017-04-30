assert = require 'assert'
sinon = require 'sinon'
proxyquire = require 'proxyquire'

Queuer = {
  findAllByMatchId: ->
}
tdbMock = {
  models: {
    Queuer: Queuer
  }
}
MatchMaker = proxyquire('../../../services/match-maker', {
  'database': tdbMock

})

describe "Matchmaker", ->
  describe "checkEnoughPlayersForMatch", ->
    queuers = []
    beforeEach ->


    xit "Should find a match when there's 2 teams of 3", (done) ->
      queuers = [
        { userIds: [1, 2, 3] }
        { userIds: [4, 5, 6] }
      ]
      queuer = {get: sinon.stub().calledWith('userIds').returns([4, 5, 6])}
      MatchMaker.checkEnoughPlayersForMatch queuer, (err, players) ->
        done()

    it "Should not do anything when there's only one team of 3", ->

  describe "checkPlayersAreConfirmed", ->

    xit "Should run and send players to game if no unconfirmed queuers were found", (done) ->
      sinon.stub(MatchMaker, 'sendToGame').callsArgWith(1, null, {})
      queuers = [{get: ((item) -> @[item]), userIds:[], confirmedUserIds: []}]
      sinon.stub(Queuer, 'findAllByMatchId').callsArgWith(1, null, queuers)
      MatchMaker.checkPlayersAreConfirmed 123, (err, res) ->
        assert MatchMaker.sendToGame.calledOnce
        done()

  describe "acceptRecieved", ->




