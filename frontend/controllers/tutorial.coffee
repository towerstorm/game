TutorialCtrl = ($scope, $location, NetService, UserService) ->
  UserService.onUserLoad ->
    NetService.createGame {mode: "TUTORIAL"}, (err, details) ->
      if err
        NetService.log('error', 'Failed to contact game server ' + NetService.gameServer.host + ' to create tutorial game')
      if details?
        setupTutorial details.server, 8082, details.code, ->
          $location.path('/game/play/'+details.server+'/'+details.code).replace();
          $scope.$apply();
          return true


  setupTutorial = (host, port, code, callback) ->
    connectUrl = "//" + host + ":" + port + "/game/" + code
    $scope.socket = io.connect(connectUrl, {'force new connection': true})
    $scope.socket.on config.netMsg.clientConnect, ->
      $scope.socket.on config.netMsg.player.details, (details) ->
        configChange = {race: 'crusaders', team: 0}
        $scope.socket.emit config.netMsg.player.configure, configChange, (success) ->
          $scope.socket.emit config.netMsg.game.start, {}, (success) =>
            if success
              callback()



TutorialCtrl.$inject = ['$scope', '$location', 'NetService', 'UserService']
window.TutorialCtrl = TutorialCtrl

