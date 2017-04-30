GameControlsDirective = () ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game/game-controls.html'
  return details
GameControlsDirective.$inject = []
angular.module('towerstorm.directives').directive "gameControls", GameControlsDirective
