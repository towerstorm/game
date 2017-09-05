MapSelectorDirective = ($rootScope) ->
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/map-selector.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.maps = [
        {
          id: "deep-space-collision"
          image: "deep-space-collision.png",
          name: "Deep Space Collision",
          description: "A cutthroat 3 vs 3 battle map"
          teams: 2,
          minPlayers: 4,
          maxPlayers: 8
        },
        {
          id: "forest-of-survival"
          image: "forest-of-survival.png",
          name: "Forest of Survival",
          description: "A fun survival map"
          teams: 1,
          minPlayers: 1,
          maxPlayers: 8
        }
      ]
      scope.selectedMap = null
      scope.isHost = false
      
      scope.$on 'game.settings.changeHost', (e, hostId, playerIsHost) ->
        scope.isHost = playerIsHost
      
      scope.$on 'game.settings.changeMap', (e, id) ->
        scope.selectedMap = _.find(scope.maps, {id: id})
        $rootScope.$broadcast("game.map.info", scope.selectedMap) 
      
      scope.selectMap = (id) ->
        if !scope.isHost
          return
        scope.selectedMap = _.find(scope.maps, {id: id})
        $rootScope.$broadcast('game.action.selectMap', id)
        
      
      
MapSelectorDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("mapSelector", MapSelectorDirective)