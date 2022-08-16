var rg = require("require-glob");
const path = require('path');

module.exports = function (folder) {
	
  var items = rg.sync(__dirname + "/" + folder + "/*.js", {keygen: function (options, file)      
  { 
      //console.log("Loading item: " + file.path.replace(file.base + path.sep, '').replace(/.\w*$/, ''));
      return file.path.replace(file.base + path.sep, '')
      .replace(/.\w*$/, ''); }});
	
  return items;
}
