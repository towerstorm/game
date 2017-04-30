TowerButtonsDirective = ($parse) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game/tower-buttons.html'
    scope: {
      unpickTower: '='
    }


    link: (scope, element, attrs) ->
      scope.towerButtons = [];
      scope.highlighted = null
      scope.pickedTower = null

      scope.$on 'game.ts.loaded', ->
        ts.game.dispatcher.on ts.getConfig('gameMsg', 'pickedTower'), (towerType) ->
          scope.pickedTower = towerType
          scope.safeDigest()

      scope.safeDigest = (fn) ->
        phase = @$root.$$phase
        if phase is "$apply" or phase is "$digest"
          fn()  if fn and (typeof (fn) is "function")
        else
          @$digest fn

      scope.$on 'game.towerButtons.update', (e, buttons) ->
        scope.towerButtons = buttons
        scope.safeDigest()

      scope.$on 'game.towerButtonStates.update', (e, buttonStates) ->
        scope.buttonStates = buttonStates
        scope.safeDigest()

      scope.$on 'game.highlighted.update', (e, highlighted) ->
        scope.highlighted = highlighted
        scope.safeDigest()

      scope.$on 'game.unpickTower', ->
        scope.pickedTower = null
        scope.safeDigest()

      scope.clickPickTower = (towerType) ->
        scope.pickedTower = towerType
        ts.game.dispatcher.emit ts.getConfig('gameMsg', 'pickTower'), towerType

  return details
TowerButtonsDirective.$inject = ['$parse']
angular.module('towerstorm.directives').directive "towerButtons", TowerButtonsDirective
