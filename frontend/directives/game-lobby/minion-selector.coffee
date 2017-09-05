MinionSelectorDirective = ($rootScope) ->
  mainPlayerId = null
  
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/minion-selector.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.minions = []
      scope.minionSelectionAvailable = true
      scope.selectedMinion = null
      scope.chosenMinions = {}
      
      minions = window.config.minions
      for id, minion of minions 
        scope.minions.push({
          id: id,
          name: minion.name
        }) 
      
      scope.selectMinion = (id) ->
        if scope.selectedMinion && scope.selectedMinion.id == id
          return scope.chooseMinion(scope.selectedMinion.id)
        scope.selectedMinion = _.find(scope.minions, {id: id})
        $rootScope.$broadcast('game.action.selectRace', null)
        $rootScope.$broadcast('game.action.selectMinion', id)
        
      scope.chooseMinion = (id) ->
        $rootScope.$broadcast('game.action.chooseMinion', id)
        
      scope.$on 'game.settings.mainPlayerId', (e, pid) ->
        mainPlayerId = pid
        
      scope.$on 'game.player.changed', (e, player) ->
        if player.id == mainPlayerId
          scope.chosenMinions = {}
          player.minions.forEach((id) -> scope.chosenMinions[id] = id) 
          
      scope.$on 'game.map.info', (e, mapInfo) ->
        if mapInfo.teams < 2
          scope.minionSelectionAvailable = false
          
          
          
        
  return details
      
      
MinionSelectorDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("minionSelector", MinionSelectorDirective)