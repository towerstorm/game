CreateGameCtrl = ($scope, $location, NetService, UserService) ->
  startTime = Date.now();
  UserService.onUserLoad ->
    NetService.createGame {mode: "PVP"}, (err, details) ->
      if err
        NetService.log('error', 'Failed to contact game server ' + NetService.gameServer.host + ' to create game')
      if details?
        NetService.timing('frontEnd.createGame', Date.now() - startTime);
        $location.path('/game/lobby/'+details.server+'/'+details.code).replace();

CreateGameCtrl.$inject = ['$scope', '$location', 'NetService', 'UserService']
window.CreateGameCtrl = CreateGameCtrl