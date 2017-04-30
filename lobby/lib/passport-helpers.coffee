tdb = require 'database'
User = tdb.models.User
netconfig = require 'config/netconfig'
passport = require 'passport'
LocalStrategy = require('passport-local').Strategy
log = require('logger')
debug = require('debug')('lib:passport-helpers');

LOBBY_URL = "http://" + netconfig.lobby.host + ":" + netconfig.lobby.port

formatUserForReq = (user) ->
  return {id: user.get('id'), role: user.get('role')}

auth =
  localStrategy: ->
    return new LocalStrategy({
      passReqToCallback: true
    }, (req, username, password, done) ->
      debug("Starting local strategy");
      if req.user
        debug("Returning from local strategy as we already have a user");
        done(null, req.user)
      else if username == 'temp' || username == 'bot'
        debug("Creating temp user as username is: " + username);
        User.createTempUser username, (err, user) ->
          if err
            log.error(err.message)
            return done(err)
          done(err, formatUserForReq(user))
      else
        debug("Attempting to find user by username: " + username + " password: " + password);
        User.findByUsernamePassword username, password, (err, user) ->
          if err
            log.warn(err.message)
            return done(err)
          done(err, formatUserForReq(user))
    )

  ###
    How Social logins work:
    - If a user is not logged in it tries to find them by their social account id.
      - If it can find them it logs them in as that account
      - If it cannot find them it creates a new account for them tying that social account to it.
    - If a user is logged in it tries to find them by their social account
      - If it can find them it logs them in as that account
      - If it cannot find them it adds their social account to the exisiting account.
  ###

  setupUser: (provider, profileId, profile, req, done) ->
    if !req.user
      User.findOrCreateOauthUser provider, profileId, profile, (err, user) ->
        done(err, formatUserForReq(user))
    else
      User.findByProviderId provider, profileId, (err, user) ->
        if !err? && user?
          log.info("Found by providerid ", profileId)
          done(err, formatUserForReq(user))
        else
          log.info("Did not find by providerid ", profileId)
          User.findById req.user.id, (err, user) ->
            if err then return done(err)
            user.addOauthProvider provider, profileId, profile, (err, user) ->
              log.info("Added oauth provider ", profileId)
              done(err, formatUserForReq(user))


  serializeUser: (user, done) ->
    debug("(" + Date.now() + ") Serializing user: ", user)
    userId = if user.get? then user.get('id') else user.id
    done(null, userId);

  deserializeUser: (id, done) ->
    debug("(" + Date.now() + ") Deserializing id " + id)
    User.findById id, (err, user) ->
      if !user
        log.warn("(" + Date.now() + ") Did not find user of id " + id)
        return done(null, false)
      debug("(" + Date.now() + ") Found user of id " + id)
      done(err, formatUserForReq(user))

module.exports = auth
