require('coffee-script/register');
var db = require('../lib/rethinkdb-client');
var async = require('async');

var totalConnections = 1;
var incrementMultiplier = 2;
var totalIncrements = 15;
async.timesSeries(totalIncrements, function (n, callback) {
  totalConnections *= incrementMultiplier;
  console.log("Testing " + totalConnections + " connections");
  async.times(totalConnections, function(n, done) {
    db.onConnect(function(err, connection) {
      if (err) {
        console.log("onConnect returned error: " + err.message)
        return done(err)
      }
      db.table('test').insert({test: 'test'}).run(connection, function (err, res) {
        connection.close();
      });
      done(null, true)
    });
  }, function (err, connections) {
    if (err) {
      console.log("Total connections failed");
      return callback(err)
    }
    console.log(totalConnections + " returned successfully")
    callback(null, true)
  });
}, function (err, results) {
  if (err) {
    return console.log("Failed")
  }
  return console.log("Success!")
});
