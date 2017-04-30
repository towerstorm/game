PlayerInfoDirective = () ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game/player-info.html'
    scope: {}

    link: (scope, element, attrs) ->
      scope.highlighted = null

      scope.safeDigest = (fn) ->
        phase = @$root.$$phase
        if phase is "$apply" or phase is "$digest"
          fn()  if fn and (typeof (fn) is "function")
        else
          @$digest fn

      scope.$on 'game.gold.update', (e, gold) ->
        scope.gold = gold
        scope.safeDigest()

      scope.$on 'game.income.update', (e, income) ->
        scope.income = income
        scope.safeDigest()

      scope.$on 'game.souls.update', (e, souls) ->
        scope.souls = souls
        scope.safeDigest()

      scope.$on 'game.time.update', (e, time) ->
        secondsPassed = time % 60
        if secondsPassed < 10
          secondsPassed = "0" + secondsPassed
        scope.timeFormatted = Math.floor(time / 60) + ":" + secondsPassed
        scope.safeDigest()

      scope.$on 'game.highlighted.update', (e, highlighted) ->
        scope.highlighted = highlighted
        scope.safeDigest()

  return details
PlayerInfoDirective.$inject = []
angular.module('towerstorm.directives').directive "playerInfo", PlayerInfoDirective
