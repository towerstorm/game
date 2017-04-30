PlayerPanelDirective = ($rootScope) ->
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/player-panel.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.isHost = false
      scope.state = attributes.state;
      
      player = JSON.parse(attributes.player)
      Object.keys(player).forEach((key) -> scope[key] = player[key])
      
      scope.$on 'game.settings.changeHost', (e, hostId, playerIsHost) ->
        scope.isHost = playerIsHost
        
      scope.isInLobby = () ->
        return scope.state == config.general.states.lobby
        
      scope.isInSelection = () ->
        return scope.state == config.general.states.selection
      
  return details
  
PlayerPanelDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("playerPanel", PlayerPanelDirective)