MinionSelectorDirective = ($rootScope) ->
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/minion-selector.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.minions = []
      scope.selectedMinion = null
      
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
        
        
  return details
      
      
MinionSelectorDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("minionSelector", MinionSelectorDirective)