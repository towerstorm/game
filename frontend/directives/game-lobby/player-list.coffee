PlayerListDirective = ($rootScope) ->
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/player-list.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.state = config.general.states.lobby;
      scope.team = parseInt(attributes.team, 10);
      scope.colorClass = getTeamColorClass(scope.team)
      
      scope.players = []
      
      scope.$on 'game.player.changed', (e, player) ->
        if scope.players.filter((p) -> p.id == player.id).length > 0
          scope.players = removePlayer(scope.players, player)
        if player.team == scope.team 
          scope.players = addPlayer(scope.players, player)
          
      scope.selectTeam = (team) ->
        $rootScope.$broadcast('game.action.selectTeam', team)
        
      scope.$on 'game.settings.state', (e, state) ->
        scope.state = state
        
      scope.isInLobby = () ->
        return scope.state == config.general.states.lobby
      
  removePlayer = (playerList, player) -> 
    return playerList.filter((p) -> return p.id != player.id)
  
  addPlayer = (playerList, player) ->
    return playerList.concat([player])
      
  getTeamColorClass = (team) ->
    teamColorClasses = {
      '1': 'danger',  # red
      '2': 'info',    # blue
      '3': 'success', # green
      '4': 'warning', # yellow
    }
    return teamColorClasses[team]
      
      
  return details

PlayerListDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("playerList", PlayerListDirective)
  