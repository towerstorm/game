
JoinGameCtrl = ($scope, $location, NetService) ->
  $scope.key = ""
  $scope.games = []
  $scope.viewLoaded = ->
    $scope.refreshGames();

  $scope.isGamesListSame = (oldList, newList) ->
    if oldList.length != newList.length
      return false
    newList.forEach (newItem) ->
      foundPair = false
      oldList.forEach (oldItem) ->
        if _.isEqual(newItem, oldItem)
          foundPair = true
      if foundPair == false
        return false
    return true


  $scope.refreshGames = ->
    NetService.lobbyGet '/game/search/state/1', (err, games) ->
      if !err && !$scope.isGamesListSame($scope.games, games)
        $scope.games = games
    setTimeout($scope.refreshGames, 1000)

  $scope.joinGame = (key) ->
    server = window.location.hostname.replace(/.towerstorm.net/, '')
    $location.path('/game/lobby/' + server + '/' + key);


JoinGameCtrl.$inject = ['$scope', '$location', 'NetService']
window.JoinGameCtrl = JoinGameCtrl