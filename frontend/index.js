require("coffee-script/register")
require('app-module-path').addPath(__dirname + "/../");
var browserify = require('browserify-middleware');
var globify = require('require-globify');
var express = require("express");
var http = require("http");
var path = require("path");
var app = express();
var connectAssets = require("connect-assets");
var fs = require("fs");
var bodyParser = require("body-parser");
var errorHandler = require("errorhandler");
var netconfig = require("config/netconfig")

browserify.settings('transform', [globify]);

app.set("port", netconfig.frontend.port);
app.set("views", __dirname + "/");
app.set("view engine", "jade");
app.use(bodyParser.urlencoded({ extended: false }))
app.use(bodyParser.json())
app.use(connectAssets({src: __dirname + "/", build: false}));
app.get('/config/client.js', browserify(__dirname + '/../config/client.js'));

var gameAssets = {}
app.use("/img", express.static(path.join(__dirname, '/assets/img/')));
app.use("/dist", express.static(path.join(__dirname, '/dist')));
app.use(express.static(path.join(__dirname, "")));

var router = express.Router();
app.use('/', router);

if (app.get("env") == "development") {
  app.use(errorHandler())
}

var appInfo = require("../package.json")
app.get("/", function (req, res) {
  res.render('index',
  {
    title: 'towerstorm',
    nodeEnv: process.env.NODE_ENV,
    gameAssets: gameAssets,
    gameVersion: appInfo.version,
  });
});

http.createServer(app).listen(app.get("port"), function() {
  console.log("Frontend running on port " + app.get("port"));
});
