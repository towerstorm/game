app = require('../../../lib/app.coffee')
request = require("supertest")(app)
assert = require('assert')


describe "/auth", ->
  describe "/temp", ->
    userData = {username: 'temp', password: '2'}
    cookies = null

    it "Should create a temporary user when called with username and password variables", (done) ->
      request.get('/auth/temp')
      .send(userData)
      .expect('Content-Type', /json/)
      .expect(200)
      .end (err, res) ->
        if err then return done(err)
        cookies = res.headers['set-cookie'].pop().split(';')[0];
        done()

    it "Should be able to access /user after it's created", (done) ->
      request.get('/auth/temp').send(userData).end (err, res) ->
        req = request.get('/user/')
        req.cookies = cookies
        req.expect(200)
        .end (err, res) ->
          if err then return done(err)
          userInfo = JSON.parse(res.text)
          assert.equal(userInfo.stormPoints, 0);
          done()

