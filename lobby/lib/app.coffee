netconfig = require("config/netconfig")
debug = require("debug")("ts:lobby")

process.env.PORT = netconfig.lobby.port
hostname = process.env.C9_HOSTNAME || process.env.HOSTNAME || "ts.devel"
nv = process.env.NODE_ENV || "development"

debug("Cookie hostname is: " + hostname);

express = require('express')
cookieParser = require('cookie-parser')
bodyParser = require('body-parser')
session = require("express-session")
passport = require 'passport'
passportHelpers = require("./passport-helpers")
tdb = require('database')
sessionStore = tdb.sessionStore
config = require('config/lobby')
log = require('logger')

app = express();

app.set "port", process.env.PORT
app.set "jsonp callback", true
app.use(cookieParser())
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())

sessionCookie = {
  path: '/'
  maxAge: 1000 * 60 * 24 * 365
  domain: hostname #This has to be here even on dev for cookie to save and work properly.
}

app.use(session({
  key: config.cookieKey,
  secret: config.cookieSecret,
  store: sessionStore
  cookie: sessionCookie
  resave: true
  saveUninitialized: true
}))
app.use(passport.initialize())
app.use(passport.session())

passport.use(passportHelpers.localStrategy())
passport.serializeUser(passportHelpers.serializeUser)
passport.deserializeUser(passportHelpers.deserializeUser)

router = express.Router()
require("./router")(router)
app.use('/', router)
app.use(require('./error-handler'))

module.exports = app
