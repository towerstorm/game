InstantActionCtrl = ($scope, $location, NetService, UserService) ->
  UserService.onUserLoad ->
    NetService.createGame {mode: "PVP"}, (err, details) ->
      if err
        NetService.log('error', 'Failed to contact game server to create game in instant action')
      if details?
        setupInstantAction details.server, 8082, details.code, ->
          $location.path('/game/play/'+details.server+'/'+details.code).replace();
          $scope.$apply();
          return true


  setupInstantAction = (host, port, code, callback) ->
    if host != "localhost" && host.match(/[a-z]+/)? #Server is a simple string not a url and is not localhost so append .towerstorm.net
      host += ".towerstorm.net"
    connectUrl = "//" + host + ":" + port + "/game/" + code
    $scope.socket = io.connect(connectUrl, {'force new connection': true})
    $scope.socket.on config.netMsg.clientConnect, ->
      $scope.socket.on config.netMsg.player.details, (details) ->
        configChange = {race: 'crusaders', team: 0}
        successCount = 0
        checkSuccess = (success) ->
          if success
            successCount++
            if successCount >= 5
              $scope.socket.emit config.netMsg.player.configure, configChange, (success) ->
                setTimeout =>
                  $scope.socket.emit config.netMsg.game.start, {}, (success) =>
                    if success
                      callback()
                , 1000
        addBot 0, 'shadow', (success) =>
          checkSuccess(success)
          addBot 0, 'droids', (success) =>
            checkSuccess(success)
            addBot 1, 'elementals', (success) =>
              checkSuccess(success)
              addBot 1, 'crusaders', (success) =>
                checkSuccess(success)
                addBot 1, 'architects', (success) =>
                  checkSuccess(success)
    $scope.socket.on config.netMsg.game.details, (details) ->
      console.log "Got game details of ", details

  addBot = (team, race, callback) =>
    setTimeout =>
      $scope.socket.emit config.netMsg.game.addBot, {team, race}, (success) ->
        callback(success)
    , 500




InstantActionCtrl.$inject = ['$scope', '$location', 'NetService', 'UserService']
window.InstantActionCtrl = InstantActionCtrl
