GameInvitesDirective = ($location, NetService, UserService) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game-invites-list.html'
    link: ($scope, element, attrs) ->

      updateInvitesList = (user) ->
        $scope.invites = user.lobbyInvitations

      $scope.$on 'user.updated', ->
        updateInvitesList(UserService.user)

      UserService.onUserLoad ->
        updateInvitesList(UserService.user)

      $scope.acceptInvitation = (lobbyId) ->
        NetService.lobbyGet '/lobby/' + lobbyId + '/invite/accept', (err, res) ->
          if err then return console.error("Failed to accept lobby invite err: ", err)
          UserService.loadUser (err, user) ->
            if !err then updateInvitesList(user)
          $location.path('/lobby/' + lobbyId)


      $scope.declineInvitation = (lobbyId) ->
        NetService.lobbyGet '/lobby/' + lobbyId + '/invite/decline', (err, res) ->
          if err then return console.error("Failed to decline lobby invite err: ", err)
          UserService.loadUser (err, user) ->
            if !err then updateInvitesList(user)




  return details

GameInvitesDirective.$inject = ['$location', 'NetService', 'UserService']
angular.module('towerstorm.directives').directive "gameInvites", GameInvitesDirective
