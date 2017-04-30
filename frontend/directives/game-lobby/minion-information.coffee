MinionInformationDirective = ($rootScope) ->
  details = 
    restrict: 'EA'
    templateUrl: 'templates/game-lobby/minion-information.html'
    scope: {}
    
    link: (scope, element, attributes) ->
      scope.minionId = null
      
      $rootScope.$on 'game.action.selectMinion', (e, minionId) ->
        minionInformation = getMinionInformation(minionId)
        Object.keys(minionInformation).forEach((key) -> scope[key] = minionInformation[key])
        
  shownAttributes = ['health', 'speed', 'cost', 'value', 'souls', 'income', 'moveType']
        
  getMinionInformation = (minionId) ->
    minionInformation = {}
    minionInformation.minionId = minionId
    if minionId == null
      return minionInformation
    
    minion = window.config.minions[minionId]
    minionInformation.name = minion.name
    shownAttributes.forEach((attribute) -> minionInformation[attribute] = minion[attribute])
    return minionInformation
      
  return details
      
MinionInformationDirective.$inject = ['$rootScope']
angular.module("towerstorm.directives").directive("minionInformation", MinionInformationDirective)