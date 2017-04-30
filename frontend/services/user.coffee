angular.module('userService', []).factory('UserService', ['$cookieStore', '$interval', '$rootScope', 'AnalyticsService', 'NetService', ($cookieStore, $interval, $rootScope, AnalyticsService, NetService, PubNub) ->

  accessLevels = authConfig.accessLevels
  userRoles = authConfig.userRoles
  cookieUser = $cookieStore.get('user') || null
  refreshUserTime = 1000
  moduleStartTime = Date.now();
  noop = -> true

  isTemp = (user) ->
    if user && user.role != "temp"
      return false
    else
      return true

  class User
    user: cookieUser
    tempUsername: null
    accessLevels: accessLevels
    userRoles: userRoles
    reloadUserTimer: null
    onlineFriends: {}
    subscribedPersonalChannel: false
    socket: null

    constructor: ->
      @loadOrCreateTempUser (err, user) =>
        @updateUser(user)
      @tempUsername = "Guest"
      @connect()
      @onUserChange (user) =>
        #@subscribePersonalChannel(user)
        #@subscribeFriendsChannels(user)
        AnalyticsService.identify(user.id, {username: user.username, email: user.email})
      @onUserLoad (user) =>
        NetService.timing('frontEnd.user.load', Date.now() - moduleStartTime);

    connect: () ->
      if @socket?
        @socket.disconnect()
      NetService.lobbyGet '/', (err, data) =>
        if err then return console.error("Failed to find lobby server, err is: " + err)
        if @socket?
          @socket.socket.reconnect()
        else
          @socket = io.connect("//" + data.server + ":" + NetService.lobbyServer.port + "/sockets/user", {
            'reconnect': true,
            'reconnection delay': 500,
            'max reconnection attempts': 10
          })
          @socket.on 'connect', ->
            console.log("Player connected to lobby")
          @socket.on 'user.details', (user) =>
            @updateUser(user)


    getUsername: ->
      if @user?
        return @user.username
      else
        return @tempUsername

    getUserId: ->
      if @user?
        return @user.id
      else
        console.log "Attempted to get userId of null user"
        return 0;

    ###
      Calls the callback only once ever.
    ###
    onUserLoad: (callback) ->
      if @user?
        _.defer =>
          callback(@user)
      else
        $rootScope.$on 'user.updated', _.once(=> callback(@user))

    ###
      Calls callback every time the user changes
    ###
    onUserChange: (callback) ->
      if @user?
        _.defer =>
          callback(@user)
      $rootScope.$on 'user.updated', =>
        callback(@user)

    ###
      Calls callback every time the onlineFriends changes
    ###
    onOnlineFriendsChange: (callback) ->
      if @onlineFriends?
        _.defer =>
          callback(@onlineFriends)
      $rootScope.$on 'user.onlineFriends.updated', =>
        callback(@onlineFriends)

    hasUsername: ->
      if !@user || !@user.username || @user.username.match(/GuestUser\.[a-zA-Z0-9]{4}/i)
        return false
      return true

    saveUsername: (newUsername, callback = noop) ->
      NetService.lobbyGet "/user/update/username/" + newUsername,  (err, data) =>
        if err then return callback(err, null)
        @user.username = newUsername
        @updateUser(@user)
        return callback(null, @user)

    loadOrCreateTempUser: (callback) ->
      @loadUser (err, user) =>
        if !user?
          @createTempUser (err, user) =>
            if callback?
              callback(err, user)


    loadUser: (callback) ->
      @getDetails (err, user) =>
        if user?
          @updateUser(user)
        if callback?
          callback(err, user)

    updateUser: (user) ->
      if !user? || !user.id?
        return false
      if !_.isEqual(user, @user)
        @updateUserCookie(user)
        if @user?.id? && user.id != @user.id
          _.defer =>
            @connect() #Reconnect to establish socket with new user id.
        @user = user
        $rootScope.$broadcast('user.updated')

    updateUserCookie: (user) ->
      cookieUser =
        id: user.id
        username: user.username
        role: user.role
        level: user.level
        stormPoints: user.stormPoints
      $cookieStore.put('user', cookieUser)

    isRegistered: (callback = noop) ->
      if @user?
        callback(null, !isTemp(@user))
      @getDetails (err, user) ->
        if err?
          return callback(err, false)
        return callback(null, !isTemp(user))

    authorize: (accessLevel, role) ->
      return true

    logout: (callback) ->
      NetService.lobbyGet "/user/logout", (err, data) ->
        if err?
          console.log "Recieved error while logging out: ", err
        else
          console.log "Successfully logged out"

    getDetails: (callback) ->
      NetService.lobbyGet "/user", (err, data) ->
        if err?
          return callback(err, null)
        callback(null, data)

    createTempUser: (callback) ->
      startTime = Date.now()
      NetService.lobbyGet "/auth/temp?username=temp&password=2", (err, user) =>
        if err?
          return callback(err, null)
        if user?
          @updateUser(user)
        NetService.timing('frontEnd.user.createTempUser', Date.now() - startTime);
        callback(err, user)

    acceptFriendRequest: (userId, callback = noop) ->
      NetService.lobbyGet "/user/friends/accept/#{userId}", (err, res) =>
        if err then return callback(err)
        callback(null, true)

    declineFriendRequest: (userId, callback = noop) ->
      NetService.lobbyGet "/user/friends/decline/#{userId}", (err, res) =>
        if err then return callback(err)
        callback(null, true)

    addFriend: (name, callback = noop) ->
      NetService.lobbyGet "/user/friends/add/#{name}", (err, res) =>
        if err then return callback(err)
        callback(null, true)

    subscribePersonalChannel: (user) ->
      if !PubNub._instance || @subscribedPersonalChannel
        return false
      channelName = 'onlineFriends-' + user.id
      PubNub.ngSubscribe({
        channel: channelName
        presence: (events, payload) =>
          console.log("Got presence from subscribe args: ", arguments)
          if events?
            for event in events
              if event.action in ['timeout', 'leave']
                @friendOffline(event.uuid)
              if event.action in ['join']
                @friendOnline(event.uuid)
        heartbeat: 30
      })
      $rootScope.$on PubNub.ngMsgEv(channelName), (event, payload) =>
        console.log("Got message event: ", event, " payload: ", payload)
      $rootScope.$on PubNub.ngPrsEv(channelName), (event, payload) =>
        console.log("Got presence event: ", event, " payload: ", payload)
        userDataMap = PubNub.ngPresenceData(channelName)
        console.log("User data map: ", userDataMap)
        @updateOnlineFriends(PubNub.ngListPresence(channelName))
      PubNub.ngHereNow({ channel: channelName })
      @subscribedPersonalChannel = true

    subscribeFriendsChannels: (user) ->
      if user.friends
        for friend in user.friends
          channelName = 'onlineFriends-' + friend.id
          PubNub.ngSubscribe({ channel: channelName })
          PubNub.ngHereNow({ channel: channelName })

    updateOnlineFriends: (userList) ->
      @onlineFriends = _.zipObject(userList, userList)
      console.log("online friends: ", @onlineFriends)
      $rootScope.$broadcast('user.onlineFriends.updated', @onlineFriends)

    friendOnline: (userId) ->
      @onlineFriends[userId] = userId
      $rootScope.$broadcast('user.onlineFriends.updated', @onlineFriends)

    friendOffline: (userId) ->
      @onlineFriends[userId] = null
      $rootScope.$broadcast('user.onlineFriends.updated', @onlineFriends)

  return new User
]);