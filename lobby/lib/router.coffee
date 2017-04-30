
fs = require 'fs'
_ = require 'lodash'
routes = require './routes'
ensureAuthorized = require './ensure-authorized'

router = (app) ->
  _.each routes, (route) ->
    route.middleware.unshift(ensureAuthorized)
    args = _.flatten([route.path, route.middleware])
    switch route.httpMethod.toUpperCase()
      when 'GET' then app.get.apply(app, args)
      when 'POST' then app.post.apply(app, args)
      when 'PUT' then app.put.apply(app, args)
      when 'DELETE' then app.delete.apply(app, args)

module.exports = router
