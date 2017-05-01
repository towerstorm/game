RaceSelectorDirective = ($rootScope) ->
  mainPlayerId = null
  mainPlayerTeam = 1
  
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/race-selector.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.races = []
      scope.takenRaces = {}; # raceId -> playerId
      scope.selectedRace = null
      scope.chosenRace = null
      
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
        scope.selectedRace = null
        $rootScope.$broadcast('game.action.chooseRace', id)
        
      scope.otherPlayerChoseRace = (raceId, playerId, team) ->
        if team != mainPlayerTeam || mainPlayerId == playerId
          return
        currentRace = _.findKey(scope.takenRaces, {id: playerId})
        if currentRace
          delete scope.takenRaces[currentRace] 
        if raceId
          scope.takenRaces[raceId] = {id: playerId}
          
      scope.$on 'game.settings.mainPlayerId', (e, pid) ->
        mainPlayerId = pid
        
      scope.$on 'game.player.changed', (e, player) ->
        if player.id != mainPlayerId
          return scope.otherPlayerChoseRace(player.race, player.id, player.team)
        mainPlayerTeam = player.team
        if player.race
          scope.chosenRace = _.find(scope.races, {id: player.race})
          
        
  return details
      
RaceSelectorDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("raceSelector", RaceSelectorDirective)