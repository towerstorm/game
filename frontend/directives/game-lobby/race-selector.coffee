RaceSelectorDirective = ($rootScope) ->
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/race-selector.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.races = []
      scope.selectedRace = null
      
      races = window.config.races
      for name, race of races
        raceImageNum = race.imageNum
        imagePosX = (raceImageNum % 8 * 32)
        imagePosY = ((raceImageNum - (raceImageNum % 8)) / 8) * 32
  
        scope.races.push
          id: race.id
          name: race.name
          description: race.description
          imagePosX: imagePosX
          imagePosY: imagePosY
          
      scope.selectRace = (id) ->
        if scope.selectedRace && scope.selectedRace.id == id
          return scope.chooseRace(id)
        scope.selectedRace = _.find(scope.races, {id: id})
        $rootScope.$broadcast('game.action.selectMinion', null)
        $rootScope.$broadcast('game.action.selectRace', id)
        
      scope.chooseRace = (id) ->
        $rootScope.$broadcast('game.action.chooseRace', id)
        
  return details
      
RaceSelectorDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("raceSelector", RaceSelectorDirective)