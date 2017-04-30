ChooseUsernameDirective = ($parse, $modal, UserService) ->
  details =
    restrict: 'AE'
    scope: {}
    link: (scope, element, attrs) ->
      modal = null
      scope.user = UserService.user
      scope.newUser = {name: ""}
      scope.userIsRegistered = false
      scope.error = null

      showChooseUsername = ->
        if !modal
          modal = $modal.open({templateUrl: 'templates/choose-username.html', scope: scope})

      UserService.onUserChange () ->
        UserService.isRegistered (err, result) ->
          if err then return
          scope.userIsRegistered = result
          if !UserService.hasUsername() && scope.userIsRegistered
            showChooseUsername()
          if UserService.hasUsername() && modal
            modal.close()
            modal = null

      scope.saveUsername = () ->
        UserService.saveUsername scope.newUser.name, (err, result) ->
          if err
            scope.error = err
          else
            if modal
              modal.close();
              modal = null

  return details
ChooseUsernameDirective.$inject = ['$parse', '$modal', 'UserService']
angular.module('towerstorm.directives').directive "chooseUsername", ChooseUsernameDirective
