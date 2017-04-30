MatchFoundDirective = ($interval, $modal, NetService) ->
  details =
    restrict: 'AE'
    link: ($scope, element, attrs) ->
      modal = null
      timer = null
      queuerId = null
      visible = false
      $scope.accepted = false
      $scope.acceptTime = 15
      $scope.timeRemainingFraction = 100
      oldTitle = window.document.title

      updateTimeRemaining = ->
        $scope.timeRemaining = (($scope.findTime + ($scope.acceptTime * 1000)) - Date.now()) / 1000
        $scope.timeRemainingFraction = Math.round(($scope.timeRemaining / $scope.acceptTime) * 100)
        spinner = ['|', '/', '-', '\\', '|', '/', '-', '\\']
        spinnerIcon = spinner[Math.round($scope.timeRemainingFraction / 4) % spinner.length]
        if spinnerIcon
          window.document.title = spinnerIcon + " MATCH FOUND " + spinnerIcon

      restoreTitle = ->
        window.document.title = oldTitle

      $scope.$on 'matchFound.show', (e, qId) ->
        if visible == true
          return false
        if window.getAttention?
          window.getAttention()
        queuerId = qId
        $scope.accepted = false
        $scope.timeRemaining = $scope.acceptTime
        modal = $modal.open({templateUrl: 'templates/match-found.html', scope: $scope, backdrop: 'static', keyboard: false})
        $scope.findTime = Date.now()
        timer = $interval((-> updateTimeRemaining()), 10)
        visible = true

      $scope.$on 'matchFound.hide', (e, qId) ->
        visible = false
        restoreTitle()
        modal.close()

      $scope.accept = ->
        NetService.lobbyGet '/queue/' + queuerId + '/accept', (err, result) ->
          if err then console.log("Queuer accept returned  error: ", err)
        restoreTitle()
        $scope.accepted = true

      $scope.decline = ->
        NetService.lobbyGet '/queue/' + queuerId + '/decline', (err, result) ->
          if err then console.log("Queuer decline returned  error: ", err)
        restoreTitle()
        modal.close()

      $scope.$on '$destroy', ->
        restoreTitle()
        if timer
          $interval.cancel(timer);

  return details
MatchFoundDirective.$inject = ['$interval', '$modal', 'NetService']
angular.module('towerstorm.directives').directive "matchFound", MatchFoundDirective
