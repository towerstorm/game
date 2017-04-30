_ = require 'lodash'
routes = require './routes'
log = require('logger')
authConfig = require('database').authConfig
userRoles = authConfig.userRoles
userRolesAdvanced = authConfig.userRolesAdvanced
accessLevels = authConfig.accessLevels;

ensureAuthorized = (req, res, next) ->
  log.debug("User is: ", req.user, " route is: ", req.route)
  if !req.user || !req.user.role
    role = userRolesAdvanced.public
  else
    role = userRolesAdvanced[req.user.role]
  log.debug("User: ", req.user, " role: ", role)
  routeInfo = _.find(routes, { path: req.route.path })
  accessLevel = routeInfo.access || accessLevels.public
  if !(accessLevel.bitMask & role.bitMask)
    return res.status(403).end()
  return next();

module.exports = ensureAuthorized
