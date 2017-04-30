require('coffee-script/register');
var db = require('../lib/rethinkdb-client.coffee');

db.onConnect(function(err, conn) {
  if (err) { throw(err); }
  db.table('games').insert(data, {conflict: 'update'}).run(conn, function(err, result) {
    conn.close();
    if (err) { throw(err); }
    console.log("Got result: ", result);
  });
});