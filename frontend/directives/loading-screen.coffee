LoadingScreenDirective = ($interval, NetService) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game/loading-screen.html'
    scope: {}

    link: (scope, element, attrs) ->
      scope.started = false
      scope.assetLoadProgress = 0
      scope.pixiLoadProgress = 0
      scope.totalLoadProgress = 0
      scope.syncProgress = 0
      scope.loaded = false
      scope.assetsLoaded = false
      scope.playersLoaded = false
      scope.syncDone = true


      scope.safeDigest = (fn) ->
        phase = @$root.$$phase
        if phase is "$apply" or phase is "$digest"
          fn()  if fn and (typeof (fn) is "function")
        else
          @$digest fn

      calculateTotalLoadProgress = ->
        if scope.syncDone
          scope.syncProgress = 100
        scope.totalLoadProgress = Math.round((scope.assetLoadProgress + scope.pixiLoadProgress + scope.syncProgress) / 3)

      previousLoadProgress = 0
      checkLoadProgress = ->
        if scope.totalLoadProgress == previousLoadProgress
          if scope.totalLoadProgress >= 100
            $interval.cancel(timer)
          else
            NetService.log("error", "User stalled on loading screen, progress percent is " + scope.totalLoadProgress + " assetLoadProgress: " + scope.assetLoadProgress + " pixiLoadProgress: " + scope.pixiLoadProgress + " syncProgress: " + scope.syncProgress)
        previousLoadProgress = scope.totalLoadProgress

      scope.$on 'game.start', ->
        scope.started = true
        scope.safeDigest()

      scope.$on 'game.player.loaded', ->
        scope.loaded = true
        scope.safeDigest()

      scope.$on 'game.players.update', (e, players) ->
        scope.players = players
        scope.playersLoaded = scope.players.length > 0
        scope.safeDigest()

      window.tsloader.onComplete () ->
        scope.assetsLoaded = true

      window.tsloader.onPxProgress (percent) ->
        scope.assetLoadProgress = percent
        calculateTotalLoadProgress()
        scope.safeDigest()

      window.tsloader.onPixiProgress (percent) ->
        scope.pixiLoadProgress = percent
        calculateTotalLoadProgress()
        scope.safeDigest()

      window.tsloader.start()
      timer = $interval(checkLoadProgress, 5000)

      scope.$on "$destroy", ->
        if timer
          $interval.cancel(timer);

      scope.$on 'game.sync.needed', () ->
        scope.syncDone = false

      scope.$on 'game.sync.progress', (e, percent) ->
        scope.syncProgress = percent
        calculateTotalLoadProgress()
        scope.syncDone = percent >= 100
        scope.safeDigest()

  return details
LoadingScreenDirective.$inject = ['$interval', 'NetService']
angular.module('towerstorm.directives').directive "loadingScreen", LoadingScreenDirective
