require('app-module-path').addPath(__dirname + "/../../");
require('coffee-script/register');

var rdbManager = require('../lib/rethinkdb-manager.coffee');
rdbManager.setup(function(err, results) {
  if (err != null) {
    console.error("DB Setup error: ", err.message);
  } else {
    console.log("DB setup returned: ", results)
  }
  process.exit(0)
});
