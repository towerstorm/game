env = process.env.NODE_ENV || "development"

express = require("express")

path = require("path")
connectAssets = require("connect-assets")
bodyParser = require('body-parser')
errorHandler = require("express-error-handler")
config = require("config/botmanager")

app = express()

app.set "port", 20000
app.set "views", __dirname + "/views"
app.set "view engine", "jade"
app.use(bodyParser.json())
app.use connectAssets(src: __dirname + "/public", build: false)
app.use express.static(path.join(__dirname, "public"))

if env == "development"
  app.use(errorHandler())

router = express.Router()
require("../routes")(router)
app.use('/', router)


module.exports = app
