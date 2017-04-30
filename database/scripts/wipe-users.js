require('coffee-script/register');
var db = require("../lib/rethinkdb-client.coffee");

var eradicateDb = function (callback) {
  db.onConnect(function (err, conn) {
    if (err) return callback(err);
    db.table('users').delete().run(conn, function (err, results) {
      if (err) return callback(err);
      callback(null, true);
    });
  });
};

eradicateDb(function(err, success) {
  console.log("All done") ;
});


