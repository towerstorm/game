log = require('logger')

LogController =
  log: (req, res) ->
    if !req.param('level')
      return next(new Error("No level param"))
    if !req.param('message')
      return next(new Error("No message param"))
    userId = ''
    if req.user?
      userId = req.user.id
    log.log(req.param('level'), req.param('message'), {ip: req.ip, userId: userId, hostname: req.hostname})
    res.status(200).end()
    
  timing: (req, res) ->
    if !req.param('stat')
      return next(new Error("No stat param"))
    if !req.param('time')
      return next(new Error("No time param"))
    log.timing(req.param('stat'), req.param('time'));
    res.status(200).end();

module.exports = LogController
