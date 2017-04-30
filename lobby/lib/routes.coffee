passport = require 'passport'
AdminCtrl = require '../controllers/admin'
ApiCtrl = require '../controllers/api'
ChatCtrl = require '../controllers/chat'
GameCtrl = require '../controllers/game'
IndexCtrl = require '../controllers/index'
LobbyCtrl = require '../controllers/lobby'
LogCtrl = require '../controllers/log'
QueueCtrl = require '../controllers/queue'
UserCtrl = require '../controllers/user'
accessLevels = require('database').authConfig.accessLevels;

route = {
  get: (path, middleware, access = null) ->
    return {path, httpMethod: 'GET', middleware, access }
  post: (path, middleware, access = null) ->
    return {path, httpMethod: 'POST', middleware, access}
}

routes = [
  route.get('/', [IndexCtrl.index]),
  route.get('/closeWindow', [IndexCtrl.closeWindow]),

  route.get('/admin/games', [AdminCtrl.listGames]),
  route.get('/admin/game/:gameId', [AdminCtrl.listGame]),
  route.get('/admin/queuers', [AdminCtrl.listQueuers]),
  route.get('/admin/users', [AdminCtrl.listUsers]),

  route.get('/api/stats', [ApiCtrl.stats], accessLevels.public),
  route.get('/api/leaderboard', [ApiCtrl.leaderboard], accessLevels.public),

  route.get('/user', [UserCtrl.index], accessLevels.user),
  route.get('/user/friends', [UserCtrl.friends], accessLevels.user),
  route.get('/user/friends/add/:username', [UserCtrl.addFriend], accessLevels.user),
  route.get('/user/friends/accept/:friendId', [UserCtrl.acceptFriend], accessLevels.user),
  route.get('/user/friends/decline/:friendId', [UserCtrl.declineFriend], accessLevels.user),
  route.get('/user/update/username/:username', [UserCtrl.updateUsername], accessLevels.user),
  route.get('/user/search/username/:username', [UserCtrl.search]),
  route.get('/user/delete', [UserCtrl.delete]),

  route.get('/game/search/state/:state', [GameCtrl.findByState]),

  route.get('/auth/temp', [passport.authenticate('local', {failureRedirect: '/auth/failed'}), UserCtrl.index])
  route.get('/auth/login', [passport.authenticate('local', {failureRedirect: '/auth/failed'}), UserCtrl.index])

  route.get('/queue/:id/info', [QueueCtrl.info], accessLevels.user)
  route.get('/queue/:id/accept', [QueueCtrl.accept], accessLevels.user)
  route.get('/queue/:id/decline', [QueueCtrl.decline], accessLevels.user)

  route.get('/lobby/create', [LobbyCtrl.create], accessLevels.user)
  route.get('/lobby/:id/join', [LobbyCtrl.join], accessLevels.user)
  route.get('/lobby/:id/info', [LobbyCtrl.info], accessLevels.user)
  route.get('/lobby/:id/queue', [LobbyCtrl.queue], accessLevels.user)
  route.get('/lobby/:id/quit', [LobbyCtrl.quit], accessLevels.user)
  route.get('/lobby/:id/invite/accept', [LobbyCtrl.acceptInvitation], accessLevels.user)
  route.get('/lobby/:id/invite/decline', [LobbyCtrl.declineInvitation], accessLevels.user)
  route.get('/lobby/:id/invite/:userId', [LobbyCtrl.invite], accessLevels.user)

  route.get('/chat/create/:userId', [ChatCtrl.createPrivate], accessLevels.user)
  route.get('/chat/close/:chatId', [ChatCtrl.close], accessLevels.user)

  route.get('/log/:level', [LogCtrl.log], accessLevels.public)
  route.get('/timing/', [LogCtrl.timing], accessLevels.public)
]

module.exports = routes
