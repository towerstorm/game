mocks =
  table: (objectInstance) ->
    insert: (data, options) ->
      return mocks.table(objectInstance)
    run: (conn, callback) ->
      callback(null, objectInstance)

module.exports = mocks
