var rg = require("require-glob");
module.exports = function (folder) {
  var items = rg.sync(__dirname + "/" + folder + "/*.js", {keygen: function (options, file) { return file.path.match(/\/([^\/.]+)\./)[1]; }});
  return items;
}
