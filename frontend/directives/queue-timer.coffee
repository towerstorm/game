QueueTimer = ($interval, UserService) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/queue-timer.html'
    link: ($scope, element, attrs) ->
      startTime = null
      $scope.searchTime = null
      timer = null

      init = ->
        startTime = Date.now()
        timer = $interval(updateTime, 1000)

      updateTime = ->
        timePassed = Math.round((Date.now() - startTime) / 1000)
        $scope.searchTime = Math.floor(timePassed / 60) + ":" + timePassed % 60

      $scope.$on "$destroy", ->
        if timer
          $interval.cancel(timer);

      $scope.$on 'user.updated', ->
        user = UserService.user
        init()
#        if user && user.activeQueue != null
#          init()



  return details
QueueTimer.$inject = ['$interval', 'UserService']
angular.module('towerstorm.directives').directive "queueTimer", QueueTimer
