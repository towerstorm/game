MenuCtrl = ($scope, $rootScope,  GoogleAnalyticsService) ->

  $scope.createLobby = ->
    $rootScope.$broadcast('lobby.create')

  $scope.goFullScreen = ->
    if screenfull.enabled
      screenfull.request()


MenuCtrl.$inject = ['$scope', '$rootScope', 'GoogleAnalyticsService']
window.MenuCtrl = MenuCtrl