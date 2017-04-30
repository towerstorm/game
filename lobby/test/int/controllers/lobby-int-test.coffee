app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require 'assert'
helpers = require '../helpers'
_ = require 'lodash'

userInfo = null
describe "Lobby Integration Test", ->
  beforeEach (done) ->
    helpers.createTempUser (err, user) ->
      userInfo = user
      done()

  describe "create", ->
    it "Should create a lobby and return the id to the user", (done) ->
      req = request.get('/lobby/create')
      req.cookies = userInfo.cookies
      req.expect(200)
      .end (err, res) ->
        if err then return done(err)
        lobbyInfo = JSON.parse(res.text)
        assert(lobbyInfo.id)
        done()

  describe "join", ->
    it "Should be able to join a default public lobby", (done) ->
      helpers.createLobby userInfo.cookies, (err, lobbyInfo) ->
        if err then return done(err)
        helpers.createTempUser (err, newUserInfo) ->
          if err then return done(err)
          req = request.get('/lobby/' + lobbyInfo.id + '/join')
          req.cookies = newUserInfo.cookies
          req.expect(200).end (err, res) ->
            if err then return done(err)
            joinedLobbyInfo = JSON.parse(res.text)
            assert.equal(joinedLobbyInfo.id, lobbyInfo.id)
            assert(_.find(joinedLobbyInfo.players, {id: newUserInfo.id}))
            done()

    it "Should not be able to join a private lobby", (done) ->
      helpers.createLobby userInfo.cookies, {public: false}, (err, lobbyInfo) ->
        if err then return done(err)
        helpers.createTempUser (err, newUserInfo) ->
          if err then return done(err)
          req = request.get('/lobby/' + lobbyInfo.id + '/join')
          req.cookies = newUserInfo.cookies
          req.expect(200).end (err, res) ->
            if err then return done(err)
            joinedLobbyInfo = JSON.parse(res.text)
            assert(joinedLobbyInfo.error)

            req = request.get('/lobby/' + lobbyInfo.id + '/info')
            req.cookies = userInfo.cookies
            req.expect(200).end (err, res) ->
              newLobbyInfo = JSON.parse(res.text)
              assert.equal(newLobbyInfo.id, lobbyInfo.id)
              assert(!_.find(newLobbyInfo.players, {id: newUserInfo.id}))
              done()


  describe "quit", ->
    lobbyInfo = null

    beforeEach (done) ->
      helpers.createLobby userInfo.cookies, (err, lobby) ->
        lobbyInfo = lobby
        done()

    it "Should set lobby.active to false and remove all players if the host quits", (done) ->
      req = request.get('/lobby/' + lobbyInfo.id + '/quit')
      req.cookies = userInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return done(err)
        req = request.get('/lobby/' + lobbyInfo.id + '/info')
        req.cookies = userInfo.cookies
        req.expect(200).end (err, res) ->
          lobbyInfo = JSON.parse(res.text)
          assert(lobbyInfo.id)
          assert.equal(lobbyInfo.active, false)
          done()

    it "Should remove the player if a player other than the host quits", (done) ->
      helpers.createTempUser (err, user) ->
        invitedUserInfo = user
        if err then return done(err)
        req = request.get('/lobby/' + lobbyInfo.id + '/invite/' + invitedUserInfo.id)
        req.cookies = userInfo.cookies
        req.expect(200).end (err, res) ->
          if err then return done("Error after invite", err)
          lobbyInviteResponse = JSON.parse(res.text)
          req = request.get('/lobby/' + lobbyInviteResponse.id + '/invite/accept')
          req.cookies = invitedUserInfo.cookies
          req.expect(200).end (err, res) ->
            if err then return done("Error after invite accept", err)
            req = request.get('/lobby/' + lobbyInfo.id + '/quit')
            req.cookies = invitedUserInfo.cookies
            req.expect(200).end (err, res) ->
              if err then return done("Error after quit", err)
              req = request.get('/lobby/' + lobbyInfo.id + '/info')
              req.cookies = userInfo.cookies
              req.expect(200).end (err, res) ->
                if err then return done("Error getting lobby info", err)
                lobbyInfo = JSON.parse(res.text)
                assert(lobbyInfo.id)
                assert(!_.find(lobbyInfo.players, {id: invitedUserInfo.id}))
                done()




  describe "info", ->
    it "Should return information about the lobby", (done) ->
      helpers.createLobby userInfo.cookies, (err, lobbyInfo) ->
        if err then return done(err)
        lobbyId = lobbyInfo.id
        req = request.get('/lobby/' + lobbyId + '/info')
        req.cookies = userInfo.cookies
        req.expect(200).end (err, res) ->
          if err then return done(err)
          lobbyInfo = JSON.parse(res.text)
          assert(lobbyInfo.id)
          assert.equal(lobbyInfo.hostUserId, userInfo.id)
          assert.equal(Array.isArray(lobbyInfo.players), true)
          assert(_.find(lobbyInfo.players, {id: userInfo.id}))
          done()


  describe "invite", ->
    invitedUserInfo = null
    lobbyInfo = null
    lobbyInviteResponse = null

    beforeEach (done) ->
      helpers.createLobby userInfo.cookies, (err, lobby) ->
        lobbyInfo = lobby
        if err then return done(err)
        helpers.createTempUser (err, user) ->
          invitedUserInfo = user
          if err then return done(err)
          req = request.get('/lobby/' + lobbyInfo.id + '/invite/' + invitedUserInfo.id)
          req.cookies = userInfo.cookies
          req.expect(200).end (err, res) ->
            if err then return done(err)
            lobbyInviteResponse = JSON.parse(res.text)
            done()

    it "Should add the user to invitedUserIds and ", ->
      assert(invitedUserInfo.id in lobbyInviteResponse.invitedUserIds)

    it "Should show the lobby invite in the users profile", (done) ->
      helpers.getUserInfo invitedUserInfo.cookies, (err, info) ->
        if err then return done(err)
        foundInvitation = false
        for invitation in info.lobbyInvitations
          if lobbyInviteResponse.id == invitation.id
            foundInvitation = true
        assert.equal foundInvitation, true
        done()

    describe "acceptInvitation", ->
      lobbyAcceptResponse = null

      beforeEach (done) ->
        req = request.get('/lobby/' + lobbyInviteResponse.id + '/invite/accept')
        req.cookies = invitedUserInfo.cookies
        req.expect(200).end (err, res) ->
          if err then return done(err)
          lobbyAcceptResponse = JSON.parse(res.text)
          done()

      it "Should add user to players list in lobby and remove them from invitedUserIds", ->
        assert(invitedUserInfo.id not in lobbyAcceptResponse.invitedUserIds)
        assert(_.find(lobbyAcceptResponse.players, {id: invitedUserInfo.id}))

      it "Should remove the lobbyInvitation from user and set the users active lobby to the lobbyId", (done) ->
        helpers.getUserInfo invitedUserInfo.cookies, (err, info) ->
          if err then return done(err)
          foundInvitation = false
          for invitation in info.lobbyInvitations
            if lobbyInviteResponse.id == invitation.id
              foundInvitation = true
          assert.equal foundInvitation, false
          assert.equal info.activeLobby, lobbyInviteResponse.id
          done()

    describe "declineInvitation", ->
      lobbyDeclineResponse = null

      beforeEach (done) ->
        req = request.get('/lobby/' + lobbyInviteResponse.id + '/invite/decline')
        req.cookies = invitedUserInfo.cookies
        req.expect(200).end (err, res) ->
          if err then return done(err)
          lobbyDeclineResponse = JSON.parse(res.text)
          done()

      it "Should add user to declinedUserIds list in lobby and remove them from invitedUserIds", ->
        assert(invitedUserInfo.id not in lobbyDeclineResponse.invitedUserIds)
        assert(invitedUserInfo.id in lobbyDeclineResponse.declinedUserIds)

      it "Should remove the lobbyInvitation from the user", (done) ->
        helpers.getUserInfo invitedUserInfo.cookies, (err, info) ->
          if err then return done(err)
          foundInvitation = false
          for invitation in info.lobbyInvitations
            if lobbyInviteResponse.id == invitation.id
              foundInvitation = true
          assert.equal foundInvitation, false
          done()

  describe "queue", ->
    lobbyInfo = null
    lobbyQueueResponse = null

    beforeEach (done) ->
      helpers.createLobby userInfo.cookies, (err, lobby) ->
        lobbyInfo = lobby
        req = request.get('/lobby/' + lobbyInfo.id + '/queue')
        req.cookies = userInfo.cookies
        req.expect(200).end (err, res) ->
          if err then return done(err)
          lobbyQueueResponse = JSON.parse(res.text)
          if lobbyQueueResponse.error then return done(lobbyQueueResponse.error)
          done()

    it "Should set lobby.queuerId to an id of the created queuer", ->
      assert(lobbyQueueResponse.queuerId != null)

    it "Should set lobby.active to false", ->
      assert.equal(lobbyQueueResponse.active, false)

    it "Should have all the userIds of the players in the queue", (done) ->
      queuerId = lobbyQueueResponse.queuerId
      req = request.get('/queue/' + queuerId + '/info')
      req.cookies = userInfo.cookies
      req.expect(200).end (err, res) ->
        if err then return done(err)
        queuerInfo = JSON.parse(res.text)
        if queuerInfo.error then return done(queuerInfo.error)
        assert.deepEqual(queuerInfo.userIds, _.map(lobbyQueueResponse.players, (player) -> player.id))
        done()



