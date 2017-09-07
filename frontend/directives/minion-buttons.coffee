MinionButtonsDirective = ($parse) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game/minion-buttons.html'
    scope: {}

    link: (scope, element, attrs) ->
      scope.minionButtons = [];
      scope.highlighted = null
      scope.mapFlags = {}

      scope.safeDigest = (fn) ->
        phase = @$root.$$phase
        if phase is "$apply" or phase is "$digest"
          fn()  if fn and (typeof (fn) is "function")
        else
          @$digest fn

      scope.$on 'game.minionButtons.update', (e, buttons) ->
        scope.minionButtons = buttons
        scope.safeDigest()

      scope.$on 'game.minionButtonStates.update', (e, buttonStates) ->
        scope.buttonStates = buttonStates
        scope.safeDigest()

      scope.$on 'game.highlighted.update', (e, highlighted) ->
        scope.highlighted = highlighted
        scope.safeDigest()

      scope.$on 'game.unpickMinion', ->
        scope.pickedMinion = null
        scope.safeDigest()
      
      scope.$on 'game.map.info', (e, mapInfo) ->
        scope.mapFlags = Object.assign({}, mapInfo.flags);

      scope.clickPickMinion = (minionType) ->
        scope.pickedMinion = minionType
        ts.game.dispatcher.emit ts.getConfig('gameMsg', 'pickMinion'), minionType

  return details
MinionButtonsDirective.$inject = ['$parse']
angular.module('towerstorm.directives').directive "minionButtons", MinionButtonsDirective
