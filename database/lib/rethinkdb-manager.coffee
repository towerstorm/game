_ = require('lodash')
db = require('./rethinkdb-client')
schemas = require('config/schemas')
async = require('async')

createDatabase = (dbName, conn, callback) ->
  console.log("Creating database ", dbName)
  db.dbCreate(dbName).run(conn, callback)

createTables = (tableNames, conn, callback) ->
  asyncTasks = []
  tableNames.forEach (tableName) ->
    asyncTasks.push((done) ->
      console.log("Creating table ", tableName)
      db.tableCreate(tableName, {primaryKey: 'id'}).run(conn, done)
    )
  async.parallel(asyncTasks, callback)

createIndexes = (table, indexes, conn, callback) ->
  asyncTasks = []
  indexes.forEach (index) ->
    asyncTasks.push((done) ->
      console.log("Creating table index ", table, " - ", index)
      db.table(table).indexCreate(index).run(conn, done)
    )
  async.parallel(asyncTasks, callback)


rdbManager = {
  setup: (callback) ->
    db.onConnect (err, conn) ->
      if err then return callback(err)
      createDatabase "towerstorm", conn, (err, result) ->
        db.tableList().run conn, (err, exisitingTables) ->
          newTables = _.difference(_.keys(schemas), exisitingTables);
          console.log "Existing tables is: ", exisitingTables, " new tables is: ", newTables
          createTables newTables, conn, (err, results) ->
            if err then return callback(err, null)
            asyncTasks = []
            _.each(schemas, (details, name) ->
              asyncTasks.push((done) ->
                db.table(name).indexList().run conn, (err, existingIndexes) ->
                  newIndexes = _.difference(details.indexes, existingIndexes)
                  createIndexes(name, newIndexes, conn, done)
              )
            )
            async.parallel asyncTasks, (err, results) ->
              conn.close()
              if err then return callback(err, null)
              callback(null, results)

}

module.exports = rdbManager
