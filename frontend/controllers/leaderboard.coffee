LeaderboardCtrl = ($scope, $location, NetService, UserService) ->
  $scope.key = ""
  $scope.games = []
  $scope.currentPage = 1
  $scope.totalItems = 1
  $scope.itemsPerPage = 50

  $scope.viewLoaded = ->
    $scope.pageChanged();
    UserService.isRegistered (err, isRegistered) ->
      $scope.isRegistered = isRegistered
    loadStats(0)

  loadStats = (tries) ->
    if tries > 3
      console.log("Failed to load stats")
      return $scope.error = "Failed to contact server to load stats"
    NetService.lobbyGet '/api/stats', (err, result) ->
      if err then return _.defer(loadStats, 1000, ++tries)
      $scope.totalItems = parseInt(result.totalRegisteredPlayers)

  $scope.pageChanged = () ->
    NetService.lobbyGet '/api/leaderboard/?page=' + (parseInt($scope.currentPage) - 1), (err, players) ->
      $scope.players = players

LeaderboardCtrl.$inject = ['$scope', '$location', 'NetService', 'UserService']
window.LeaderboardCtrl = LeaderboardCtrl
