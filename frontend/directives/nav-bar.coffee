NavBarDirective = ($parse, UserService) ->
  details =
    restrict: 'EA'
    replace: true
    templateUrl: 'templates/nav-bar.html'

    link: ($scope, element, attrs) ->
      $scope.user = UserService.user
      $scope.userIsRegistered = false

      $scope.showLoginScreen = ->
        $scope.$emit('showLoginScreen')

      $scope.$on 'user.updated', ->
        $scope.user = UserService.user
        UserService.isRegistered (err, result) ->
          $scope.userIsRegistered = result


  return details
NavBarDirective.$inject = ['$parse', 'UserService']
angular.module('towerstorm.directives').directive "navBar", NavBarDirective
