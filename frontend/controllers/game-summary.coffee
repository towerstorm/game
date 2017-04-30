GameSummaryCtrl = ($cookieStore, $location, $routeParams, $scope, AnalyticsService, GameService, GoogleAnalyticsService, NetService, UserService) ->
  $scope.hashIncorrect = false
  $scope.socket = null
  $scope.screenPadding = 0;
  $scope.map = null;
  $scope.comments = "";
  $scope.endGameSign = null;
  $scope.name = "";
  $scope.address = "";

  $scope.viewLoaded = ->
    if ts?.input?
      ts.input.unbindAll()
    $scope.feedbackStep = $cookieStore.get('feedbackStep') || 0
    if $scope.feedbackStep == 3 #If we are on the superthanks page put them on the additional comments page instead.
      $scope.feedbackStep = 4
    $scope.init();

  $scope.init = =>
    $scope.gameEndResult = if GameService.didWin == true then 'Victory' else 'Defeat'
    AnalyticsService.track("On Game Summary Page", {didWin: GameService.didWin})

  $scope.goHome = ->
    $location.path("/").replace();

  $scope.goCreateNewGame = ->
    $location.path('/game/create/').replace();

GameSummaryCtrl.$inject = ['$cookieStore', '$location', '$routeParams', '$scope', 'AnalyticsService', 'GameService', 'GoogleAnalyticsService', 'NetService', 'UserService']
window.GameSummaryCtrl = GameSummaryCtrl
