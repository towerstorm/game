FriendsListDirective = ($parse, $rootScope, PubNub, UserService) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/friends-list.html'
    link: ($scope, element, attrs) ->
      $scope.friendName = ""
      $scope.addFriendButtonText = 'Add'
      $scope.addFriendButtonDisabled = false
      $scope.onlineFriends = {}

      pickIds = (arr) ->
        return _.map(arr, (item) -> _.pick(item, 'id'))

      updateFriendsList = (user) ->
        if !_.isEqual(pickIds($scope.friendRequests), pickIds(user.friendRequests))
          $scope.friendRequests = user.friendRequests
        if !_.isEqual(pickIds($scope.friends), pickIds(user.friends))
          $scope.friends = user.friends

      UserService.onUserChange (user) ->
        UserService.isRegistered (err, result) ->
          $scope.userIsRegistered = result
        updateFriendsList(user)

      UserService.onOnlineFriendsChange (onlineFriends) ->
        $scope.onlineFriends = onlineFriends

      $scope.acceptFriendRequest = (userId) ->
        UserService.acceptFriendRequest userId, (err, result) ->
          UserService.loadUser (err, user) ->
            if !err then updateFriendsList(user)

      $scope.declineFriendRequest = (userId) ->
        UserService.declineFriendRequest userId, (err, result) ->
          UserService.loadUser (err, user) ->
            if !err then updateFriendsList(user)

      $scope.addFriend = ->
        if !$scope.friendName
          return false
        $scope.addFriendError = null
        $scope.addFriendButtonText = 'Adding...'
        $scope.addFriendButtonDisabled = true
        friendName = $scope.friendName
        $scope.friendName = ""
        UserService.addFriend friendName, (err, result) ->
          if err
            $scope.addFriendError = err
          $scope.addFriendButtonText = 'Add'
          $scope.addFriendButtonDisabled = false

      $scope.startChat = (friendId, friendName) ->
        $rootScope.$broadcast 'chat.create', friendId, friendName



  return details
FriendsListDirective.$inject = ['$parse', '$rootScope', 'PubNub', 'UserService']
angular.module('towerstorm.directives').directive "friendsList", FriendsListDirective
