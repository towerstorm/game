ChatRoom = ($rootScope, PubNub, UserService) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/chat-room.html'
    scope: {
      id: '@'
    }
    link: ($scope, element, attrs) ->
      $scope.initialized = false
      $scope.id = attrs.id
      $scope.messages = []
      $scope.prefix = "" #Something to add before each message like [team]
      $scope.singleMessageMode = false

      init = ->
        if !$scope.id || $scope.initialized then return false
        PubNub.ngSubscribe({
          channel: $scope.id,
          error: -> console.log('err: ', arguments)
        })

        if attrs.prefix
          $scope.prefix = attrs.prefix

        if attrs.singleMessageMode
          $scope.singleMessageMode = true

#        PubNub.ngHistory({
#          channel: $scope.id
#          count: 100
#        })

        $rootScope.$on PubNub.ngMsgEv($scope.id), (ngEvent, payload) ->
          msg = if payload.message.user then "#{payload.message.user}: #{$scope.prefix} #{payload.message.text}" else "[unknown] #{payload.message}"
          $scope.$apply ->
            $rootScope.$broadcast('chat.unreadMessages', $scope.id)
            $scope.messages.push(msg)
        $scope.initialized = true

      $scope.publish = ->
        if !$scope.id || !$scope.newMessage
          document.activeElement = null
          return false
        PubNub.ngPublish({channel: $scope.id, message: {text: $scope.newMessage, user: UserService.getUsername()}})
        $scope.newMessage = ""
        if $scope.singleMessageMode
          element.find("input")[0].blur()

      attrs.$observe 'id', (id) ->
        $scope.id = id
        init()

      $rootScope.$on "chat.open", (e, id) ->
        if id == $scope.id
          _.defer ->
            element.find("input")[0].focus()

  return details
ChatRoom.$inject = ['$rootScope', 'PubNub', 'UserService']
angular.module('towerstorm.directives').directive "chatRoom", ChatRoom
