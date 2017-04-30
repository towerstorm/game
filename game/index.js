var path = require("path");
var MonkeyPatches = require("./lib/game/monkey-patches.coffee")
var Engine = require("./lib/engine/engine.coffee");
var PTGame = require("./lib/game/main.coffee");


function formatLog () {
  var i, len, logPieces, piece;
  logPieces = [];
  for (i = 0, len = arguments.length; i < len; i++) {
    piece = arguments[i];
    if (typeof piece === "object") {
      logPieces.push(JSON.stringify(piece));
    } else {
      logPieces.push(piece);
    }
  }
  return logPieces.join(" ");
}

function towerstormGame(game, logInfoCallback, logDebugCallback) {
  var ts;
  ts = Engine(game);
  ts.log.info = function() {
    if ((logInfoCallback != null) && typeof logInfoCallback === "object") {
      return logInfoCallback.info.apply(this, arguments);
    }
  };
  ts.log.debug = function() {
    var args, log;
    if ((logDebugCallback != null) && typeof logDebugCallback === "object") {
      args = Array.prototype.slice.call(arguments, 0);
      args.unshift(ts.getCurrentTick() + ": ");
      log = formatLog.apply(this, args);
      return logDebugCallback.info(log);
    }
  };
  return ts;
}

window.initGame = function() {
  if (window.ts) return;
  window.ts = towerstormGame(window);
  window.ts.initClasses();
  window.ts.main("#canvas", PTGame, 20, 0, 0, 1);
};
