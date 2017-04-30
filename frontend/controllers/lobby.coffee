LobbyCtrl = ($interval, $location, $modal, $rootScope, $routeParams, $scope, $timeout, NetService, UserService) ->

    $scope.active = true
    $scope.isHost = false
    $scope.openSlots = [0, 1]
    $scope.players = []
    $scope.invitedUserIds = []
    $scope.declinedUserIds = []
    $scope.chatRoomId = null
    $scope.queuerId = null
    $scope.visible = true
    $scope.onlineFriends = {}

    queueStartTime = null
    $scope.searchTime = null
    lastState = null
    timer = null
    noop = ->

    updateUser = (user) ->
      if user.friends?
        friends = _.clone(user.friends)
        for friend in friends
          if _.find($scope.players, {id: friend.id})
            friend.inGame = true
          if friend.id in $scope.invitedUserIds
            friend.invited = true
          if friend.id in $scope.declinedUserIds
            friend.declined = true
        $scope.friends = friends

    updateLobby = (lobby) ->
      $scope.id = lobby.id
      $scope.active = lobby.active
      $scope.isHost = lobby.hostUserId == UserService.getUserId()
      $scope.players = lobby.players
      $scope.openSlots = []
      for i in [$scope.players.length...3]
        $scope.openSlots.push(i)
      $scope.invitedUserIds = lobby.invitedUserIds
      $scope.declinedUserIds = lobby.declinedUserIds
      $scope.chatRoomId = lobby.chatRoomId
      if lobby.queuerId
        if !$scope.queuerId
          queueStartTime = Date.now()
        $scope.queuerId = lobby.queuerId

    updateTimer = ->
      if queueStartTime
        timePassed = Math.round((Date.now() - queueStartTime) / 1000)
        secondsPassed = timePassed % 60
        if secondsPassed < 10
          secondsPassed = "0" + secondsPassed
        $scope.searchTime = Math.floor(timePassed / 60) + ":" + secondsPassed

    updateQueuer = (queuer) ->
      if queuer.state == "confirming"
        $rootScope.$broadcast 'matchFound.show', queuer.id
      else
        if lastState == "confirming"
          $rootScope.$broadcast 'matchFound.hide'
          if queuer.state == "declined"
            $scope.showError('match-declined')
            $scope.queuerId = null
          else if queuer.state == "searching"
            $scope.showError('match-cancelled')
      lastState = queuer.state
      if queuer.state == "found" && queuer.game
        $location.path('/game/lobby/' + queuer.game.server + '/' + queuer.game.code).replace();
        $scope.$apply();

    joinLobby = (id, callback) ->
      NetService.lobbyGet '/lobby/' + $routeParams.id + '/join', (err, details) ->
        if err then return console.error("Failed to join lobby, error is: ", err)
        $scope.reloadDetails()

    $scope.reloadDetails = () ->
      if !$scope.visible
        return false
      NetService.lobbyGet '/lobby/' + $scope.id + '/info', (err, details) ->
        if err
          if err.match(/not in this lobby/)
            joinLobby($scope.id)
          return console.error("Lobby details error: ", err)
        updateLobby(details)
        $timeout((-> $scope.reloadDetails()), 1000)
      if $scope.queuerId
        NetService.lobbyGet '/queue/' + $scope.queuerId + '/info', (err, details) ->
          if err then return console.error("Queeuer details error: ", err)
          updateQueuer(details)



    UserService.onUserChange ->
      updateUser(UserService.user)

    UserService.onOnlineFriendsChange (onlineFriends) ->
      $scope.onlineFriends = onlineFriends


    $scope.viewLoaded = ->
      $scope.init();
      estimatedTime = Math.round(Math.random()*100) + 30
      secondsPassed = estimatedTime % 60
      if secondsPassed < 10
        secondsPassed = "0" + secondsPassed
      $scope.estimatedTimeFormatted = Math.floor(estimatedTime / 60) + ":" + secondsPassed
#      _.delay ->
#        $rootScope.$broadcast 'matchFound.show', 1
#      , 500

    $scope.init = ->
      $interval(updateTimer, 100)
      if $routeParams.id == "create"
        NetService.lobbyGet '/lobby/create', (err, details) ->
          if err
            $scope.showError "createLobbyFailed", ->
              $scope.goHome()
          else
            $location.path('/lobby/' + details.id).replace();
      else
        $scope.id = $routeParams.id
        $scope.reloadDetails()

    $scope.invitePlayer = (userId) ->
      $scope.invitedUserIds.push()
      NetService.lobbyGet '/lobby/' + $scope.id + '/invite/' + userId, (err, details) ->
        if err then return console.error("Lobby invite player error: ", err)

    $scope.queue = ->
      $scope.startButtonDisabled = true
      NetService.lobbyGet '/lobby/' + $scope.id + '/queue', (err, details) ->
        if err then return console.error("Lobby queue failed error: ", err)

    $scope.quitLobby = ->
      NetService.lobbyGet '/lobby/' + $scope.id + '/quit', (err, details) ->
        if err then return console.error("Lobby quit failed error: ", err)
        $location.path('/')

    $scope.startChat = (friendId, friendName) ->
      $rootScope.$broadcast 'chat.create', friendId, friendName

    $scope.showError = (error, closeCallback = noop) ->
      modalName = error.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
      modal = $modal.open({templateUrl: 'templates/error-modals/' + modalName + '.html', scope: $scope})
      modal.result.then (-> closeCallback()), (-> closeCallback())
      console.log("Error: ", error)

    $scope.goHome = ->
      $location.path("/").replace();
      $scope.$apply();

    $scope.$on '$destroy', ->
      $scope.visible = false
      $interval.cancel(timer)
      timer = null



LobbyCtrl.$inject = ['$interval', '$location', '$modal', '$rootScope', '$routeParams', '$scope', '$timeout', 'NetService', 'UserService']
window.LobbyCtrl = LobbyCtrl
