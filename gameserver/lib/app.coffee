debug = require("debug")("ts:game")
express = require("express")
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
json = require('express-json')
session = require("express-session")
passport = require 'passport'
config = require 'config/gameserver'
fs = require "fs";
tdb = require('database')
log = require('logger')
User = tdb.models.User
sessionStore = tdb.sessionStore


app = express()

hostname = process.env.C9_HOSTNAME || process.env.HOSTNAME || "ts.dev"
env = process.env.NODE_ENV || "development"

debug("Cookie hostname is: " + hostname);

sessionCookie = {
  path: '/'
  maxAge: 1000 * 60 * 24 * 365
  domain: hostname
}

app.set "port", process.env.PORT
app.set "views", __dirname + "/views"
app.set "view engine", "jade"
app.set "jsonp callback", true
# app.use express.favicon()
app.use cookieParser()
app.use(session({
  key: config.cookieKey
  secret: config.cookieSecret
  store: sessionStore
  cookie: sessionCookie
  resave: true
  saveUninitialized: true
}))
app.use json()
app.use(bodyParser.json())
app.use passport.initialize()
app.use passport.session()

app.use(require('./error-handler'))

app.set "port", process.env.PORT

passport.serializeUser((user, done) ->
  console.log "(", Date.now(), ") Serializing"
  userId = if user.get? then user.get('id') else user.id
  done(null, userId)
)

passport.deserializeUser((id, done) ->
  console.log "(", Date.now(), ") Deserializing id: ", id
  User.findById id, (err, user) ->
    if !user then return done(null, false) #Clears user session
    done(null, {id: user.get('id'), role: user.get('role')})
)

#Setup all the routes
router = express.Router()
require("./../routes")(router)
app.use('/', router)

module.exports = app
