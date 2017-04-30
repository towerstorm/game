LoginScreenDirective = ($parse, $modal, NetService, UserService) ->
  details =
    restrict: 'AE'
    link: (scope, element, attrs) ->
      modal = null
      scope.user = UserService.user
      scope.userIsRegistered = false
      scope.loginScreenValidating = false

      UserService.isRegistered (err, result) ->
        scope.userIsRegistered = result

      scope.$on 'user.updated', ->
        scope.user = UserService.user
        UserService.isRegistered (err, result) ->
          scope.userIsRegistered = result

      scope.$on 'showLoginScreen', ->
        scope.isVisible = true
        modal = $modal.open({templateUrl: 'templates/login-screen.html', scope: scope})
#        $("#loginScreen").modal('show')

      scope.hideLoginScreen = ->
        modal.close();

      scope.loginWithProvider = (name) ->
        window.open(NetService.getLobbyUrl() + "/auth/" + name, "Authorize", "height=500, width=800")
        window.onfocus = () ->
          scope.loginScreenValidating = true
          scope.checkLoggedIn()

      scope.checkLoggedIn = () ->
        window.onfocus = null
        UserService.loadUser (err, user) ->
          scope.loginScreenValidating = false
          if !user?
            scope.loginFailed = true
          else
            scope.user = UserService.user
            scope.hideLoginScreen()

      scope.hasUsername = () ->
        return UserService.hasUsername()

      scope.saveUsername = () ->
        UserService.saveUsername(scope.newUsername)

LoginScreenDirective.$inject = ['$parse', '$modal', 'NetService', 'UserService']
angular.module('towerstorm.directives').directive "loginScreen", LoginScreenDirective
