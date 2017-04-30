UserCtrl = ($scope, UserService) ->
  $scope.viewLoaded = ->
    $scope.user = UserService.user
    UserService.getDetails (err, details) ->
      if err?
        $scope.showLogin = true
      else
        $scope.user = details




UserCtrl.$inject = ['$scope', 'UserService']
window.UserCtrl = UserCtrl