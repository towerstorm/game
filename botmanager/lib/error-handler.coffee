log = require('logger')

errorHandler = (err, req, res, next) ->
  responseMessage = "Something went wrong. The server monkeys been notified of this error and will attempt to fix it ASAP."
  if err.msg #If er passed in a json object
    error = err.err
    responseMessage = err.msg
  else #If we just passed an error
    error = err
  errorMessage = if error? then error.message else ""
  errorStack = if error? then error.stack else ""
  log.error({responseMessage: responseMessage, errorMessage: errorMessage, errorStack: errorStack, ip: req.ip, host: req.host, route: req.path})
  return res.jsonp(200, {error: responseMessage})

module.exports = errorHandler