log = require('logger')

errorHandler = (err, req, res, next) ->
  responseMessage = "Something went wrong. The server monkeys been notified of this error and will attempt to fix it ASAP."
  if err.uMsg #If er passed in a json object
    error = err.err
    responseMessage = err.uMsg
  else #If we just passed an error
    error = err
  errorMessage = if error? then error.message else ""
  errorStack = if error? then error.stack else ""
  errorObject = {responseMessage: responseMessage, errorMessage: errorMessage, errorStack: errorStack, ip: req.ip, host: req.hostname, route: req.path}
  log.error("Error handler received error", {err: errorObject})
  try
    if req.hostname.match(/.tsinternal.towerstorm.com/) #From bots or other internal clients give 500 error
      return res.status(500).jsonp(errorObject)
    else #Other clients get 200 status code so ajax calls work and can pick up the error message
      return res.status(200).jsonp({error: responseMessage})
  catch e
    log.error("Had already sent headers when performing error handler", {stack: new Error().stack, err: e})

module.exports = errorHandler