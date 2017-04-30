ChatBar = ($rootScope, NetService, PubNub, UserService) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/chat-bar.html'
    link: ($scope, element, attrs) ->
      $scope.chatRooms = []

      updateChats = (user) ->
        for chatRooms in [user.openChatRooms, user.privateChatRooms]
          for chatRoom in chatRooms
            if !_.find($scope.chatRooms, {id: chatRoom.id})
              tempChat = _.find($scope.chatRooms, {name: chatRoom.name}) #If we already have a chatroom of this name but no id
              if tempChat && !tempChat.id
                tempChat.id = chatRoom.id
              else
                $scope.chatRooms.push({
                  id: chatRoom.id
                  name: chatRoom.name
                  visible: chatRoom.visible
                  open: false
                  unreadMessages: false
                })

      $scope.$on 'user.updated', ->
        updateChats(UserService.user)

      $scope.$on 'chat.create', (e, friendId, friendName) ->
        existingChat = _.find($scope.chatRooms, {name: friendName})
        if existingChat
          return $scope.toggleRoom(existingChat.id)
        NetService.lobbyGet '/chat/create/' + friendId, (err, details) ->
          console.log("Created chat room with friend ", friendId)
        $scope.chatRooms.push({id: null, name: friendName, visible: true, open: true}) #Create temporary chat without id, it can come later

      $scope.$on 'chat.unreadMessages', (e, roomId) ->
        chatRoom = _.find($scope.chatRooms, {id: roomId})
        if chatRoom
          chatRoom.visible = true
          if !chatRoom.open
            chatRoom.unreadMessages = true

      $scope.toggleRoom = (roomId) ->
        chatRoom = _.find($scope.chatRooms, {id: roomId})
        if chatRoom
          chatRoom.unreadMessages = false
          chatRoom.open = !chatRoom.open
          if chatRoom.open
            $rootScope.$broadcast('chat.open', roomId)
          chatRoom.visible = true
        for chatRoom in _.reject($scope.chatRooms, {id: roomId})
          chatRoom.open = false

      $scope.closeRoom = (roomId) ->
        NetService.lobbyGet '/chat/close/' + roomId, (err, res) ->
        chatRoom = _.find($scope.chatRooms, {id: roomId})
        if chatRoom
          chatRoom.visible = false
          chatRoom.open = false




  return details
ChatBar.$inject = ['$rootScope', 'NetService', 'PubNub', 'UserService']
angular.module('towerstorm.directives').directive "chatBar", ChatBar
