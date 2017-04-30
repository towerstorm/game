RaceInformationDirective = ($rootScope) ->
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/race-information.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.raceId = null
      
      scope.$on 'game.action.selectRace', (e, raceId) ->
        raceInformation = getRaceInformation(raceId)
        Object.keys(raceInformation).forEach((key) -> scope[key] = raceInformation[key])
        
  shownTowerAttributes = ['name', 'imageName', 'description', 'cost', 'damage', 'attackSpeed', 'range']
        
  getRaceInformation = (raceId) ->
    raceInformation = {}
    raceInformation.raceId = raceId
    if raceId == null
      return raceInformation
    
    race = window.config.races[raceId]
    raceInformation.name = race.name
    raceInformation.description = race.description
    raceInformation.towers = []
    for towerId in race.towers
      tower = window.config.towers[towerId] 
      towerInformation = {}
      shownTowerAttributes.forEach((attribute) -> 
        value = if tower[attribute] then [tower[attribute]] else []
        upgradedValues = value.concat(tower.levels.filter((level) -> level[attribute]).map((level) -> return level[attribute]))
        towerInformation[attribute] = upgradedValues.join(" / ");
      )
      raceInformation.towers.push(towerInformation)
    
    return raceInformation
    
  return details
      
      
RaceInformationDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("raceInformation", RaceInformationDirective)