GameLobbyCtrl = ($interval, $location, $modal, $scope, $rootScope, NetService, UserService, AnalyticsService, GoogleAnalyticsService) ->

  $scope.code = null
  $scope.server = null
  $scope.socket = null
  $scope.name = "Unnamed Game"
  $scope.players = []
  $scope.playerSlots = []
  $scope.playerId = null
  $scope.races = []
  $scope.maxPlayers = 6
  $scope.hostId = null
  $scope.gameDetailsUpdateTime = null
  $scope.timeRemaining = null
  $scope.countdownTimers = null
  $scope.url = window.location.href
  $scope.showInviteBox = if window.location.protocol.match(/app/) then false else true
  $scope.settings = {}
  $scope.selectedRaces = []
  $scope.actualPlayerTeam = 0 #What the server believes the players team is so that things don't switch around before the player has actually joined the other team.
  $scope.totalBots = [0, 0]
  $scope.tempBots = [0, 0]

  noop = -> true
  timer = null
  startLobbyTime = Date.now(); 
  

  connect = (host, port, code) ->
    $scope.code = code
    $scope.server = host;
    connectUrl = "//" + host + ":" + port + "/game/" + code
    UserService.onUserLoad =>
      $scope.socket = io.connect(connectUrl, {'force new connection': true})
      $scope.bindDispatcher();
      $scope.bindSockets();

  beginGame = ->
    AnalyticsService.track("Game starting - going from lobby to game",
      {
        StartIsHost: $scope.isHost(),
        StartRace: $scope.getMainPlayer().race,
        StartTeam: $scope.getMainPlayer().team,
        StartTotalPlayers: $scope.players.length,
        StartTotalHumans: $scope.getTotalHumans(),
        StartTotalBots: $scope.getTotalBots(),
        StartMode: $scope.settings.mode,
        StartMap: $scope.settings.mapId,
        StartDifficulty: $scope.settings.difficulty,
        StartTargetTime: $scope.settings.targetTime,
        StartIncomeMultiplier: $scope.settings.incomeMultiplier
      }
    )
    $location.path('/game/play/' + $scope.server + '/' + $scope.code).replace();
    $scope.$apply()

  $scope.bindSockets = ->
    $scope.socket.on config.netMsg.clientConnect, ->
    $scope.socket.on config.netMsg.player.details, (details) ->
      $scope.handleErrors(details)
      console.log "Auth details: ", details
      AnalyticsService.track('Authenticated in game lobby', {name: details.name, race: details.race})
      $scope.playerId = details.id
      $scope.changeHost($scope.hostId)
      angular.extend($scope.getMainPlayer(), {name: details.name, race: details.race, team: 0})
      $scope.$apply()
    $scope.socket.on config.netMsg.game.details, (details) ->
      console.log "Got game details of ", details
      $scope.gameDetailsUpdateTime = Date.now()
      for player in details.players
        $rootScope.$broadcast('game.player.changeTeam', player)
      $rootScope.$broadcast('game.settings.changeMap', details.settings.mapId)
      for detail in ['name', 'state', 'players', 'timeRemaining', 'settings']
        if details[detail]?
          $scope[detail] = details[detail];
      $rootScope.$broadcast('game.settings.state', $scope.state)
      $scope.changeHost(details.hostId)
      if $scope.getMainPlayer()?
        $scope.actualPlayerTeam = parseInt($scope.getMainPlayer().team, 10);
      for team in [0, 1]
        lastTotalBots = $scope.totalBots[team]
        $scope.totalBots[team] = $scope.players.filter((player) -> return player.team == team && player.isBot).length
        botsAdded = Math.max(0, ($scope.totalBots[team] - lastTotalBots)) #Don't set botsAdded to less than 0 when a bot is removed, as it will make tempBots go up
        $scope.tempBots[team] = Math.max(0, ($scope.tempBots[team] - botsAdded)) #Dont' set tempBots to less than 0, could cause issues
        console.log("Team: " + team + " totalBots: " + $scope.totalBots[team] + " last: " + lastTotalBots + " temp: " + $scope.tempBots[team])
      $scope.$apply ->
        NetService.timing('frontEnd.loadLobby', Date.now() - startLobbyTime);
    $scope.socket.on config.netMsg.game.start, ->
      beginGame()
    $scope.socket.on config.netMsg.game.error, (details) ->
      $scope.handleErrors(details);
    $scope.socket.on config.netMsg.game.kicked, ->
      $scope.showError "kicked", ->
        $scope.goHome()
    $scope.socket.on config.netMsg.game.didNotConnect, ->
      $scope.showError "didNotConnect", ->
        $scope.goHome()

  $scope.bindDispatcher = ->
    $scope.$on 'user.updated', ->
      $scope.nameNeedsRefreshing = true
      
  $scope.isInStateLobby = ->
    return $scope.state == config.general.states.lobby
    
  $scope.isInStateSelection = ->
    return $scope.state == config.general.states.selection
      
      
  $scope.changeHost = (hostId) ->
    $scope.hostId = hostId
    playerIsHost = $scope.playerId == hostId
    $rootScope.$broadcast('game.settings.changeHost', hostId, playerIsHost)

  $scope.isHost = ->
    if $scope.hostId? && $scope.playerId? && $scope.playerId == $scope.hostId
      return true
    return false

  $scope.goHome = ->
    $location.path("/").replace();
    $scope.$apply();


  $scope.handleErrors = (details) ->
    if details?.error?
      switch details.error
        when config.netMsg.game.full
          $scope.showError "gameFull", ->
            $scope.goHome();

  $scope.getTowerIconPos = (imageNum) ->
    posX = (imageNum % 8 * 32)
    posY = (((imageNum - (imageNum % 8)) / 8) * 64) + 32
    return {posX, posY}

  $scope.getPlayer = (playerId) ->
    for player in $scope.players
      if player.id == $scope.playerId
        return player;
    return null


  $scope.getMainPlayer = () ->
    if !$scope.playerId?
      return null

    for player in $scope.players
      if player.id == $scope.playerId
        return player;

    mainPlayer = new Player($scope.playerId, "", "", 0);
    $scope.players.push(mainPlayer)

    return mainPlayer

  $scope.getTotalBots = ->
    totalBots = 0;
    for player in $scope.players
      if player.isBot? && player.isBot
        totalBots++
    return totalBots

  $scope.getTotalHumans = ->
    return $scope.players.length - $scope.getTotalBots();

  $scope.changeRace = (race) ->
    mainPlayer = $scope.getMainPlayer()
    if mainPlayer.ready || $scope.takenRaces[mainPlayer.team][race]
      return false
    $scope.selectedRaces = [];
    $scope.selectedRaces.push($scope.getRaceDetails(race))
    mainPlayer.race = race
    $scope.updateValue($scope.playerId, "race")
    
  $scope.$on 'game.action.selectMap', (e, mapId) -> 
    $scope.settings.mapId = mapId
    $scope.updateSettings()
    
  $scope.$on 'game.action.selectTeam', (e, team) ->
    if $scope.getMainPlayer().ready
      return false
    $scope.getMainPlayer().team = team
    $scope.updateValue($scope.playerId, "team")

  $scope.$on 'game.action.chooseRace', (e, raceId) ->
    if $scope.getMainPlayer().ready
      return false
    $scope.getMainPlayer().race = raceId
    $scope.updateValue($scope.playerId, "race")
    
  $scope.$on 'game.action.chooseMinion', (e, minionId) ->
    if $scope.getMainPlayer().ready
      return false
    $scope.getMainPlayer().minions = $scope.getMainPlayer().minions || []
    $scope.getMainPlayer().minions.push(minionId)
    $scope.updateValue($scope.playerId, "minions")
    
  $scope.updateValue = (playerId, name) ->
    player = $scope.getPlayer(playerId)
    if !player?
      return false
    value = player[name] #get the current value of this attribute from the player to tell the server it has changed.
    configChange = {}; configChange[name] = value;
    if playerId == $scope.playerId
      $scope.socket.emit config.netMsg.player.configure, configChange, (success) ->
        if success
          AnalyticsService.track("Changed personal details", {key: name, value: value});
    else if $scope.isHost() #We're configuring a bot
      configChange['playerId'] = playerId
      $scope.socket.emit config.netMsg.game.configureBot, configChange, (success) ->
        if success
          AnalyticsService.track("Changed bot details", {id: playerId, key: name, value: value});


  $scope.addBot = (team) ->
    console.log("Adding bot to the game of team", team)
    startTime = Date.now();
    if !$scope.isHost()
      return false
    $scope.tempBots[team]++
    $scope.playersChanged();
    $scope.socket.emit config.netMsg.game.addBot, {team: team}, (err, detailsJSON) ->
      if err then return $scope.addBotFailed(err)
      try
        details = JSON.parse(detailsJSON)
      catch e
        details = {}
      if details.errno then return $scope.addBotFailed(details)
      NetService.timing('frontEnd.addBot', Date.now() - startTime);
      console.log("Added bot, details is: ", details)

  $scope.addBotFailed = (details) ->
    console.error("Failed to add bot, details is: ", details)
    $scope.showError('botAddFailed')
    $scope.tempBots = [0, 0]

  $scope.kickPlayer = (playerId) ->
    if !$scope.isHost()
      return false
    if playerId == $scope.playerId
      return false
    $scope.socket.emit config.netMsg.game.kickPlayer, playerId

  $scope.updateSettings = ->
    if !$scope.isHost()
      return false
    gameDetailsChange = {name: $scope.name, mapId: $scope.settings.mapId}
    $scope.socket.emit config.netMsg.game.configure, gameDetailsChange, (success) ->
      if success
        AnalyticsService.track("Changed game details", gameDetailsChange);

  $scope.startGame = ->
    if !$scope.isHost()
      return false
    $scope.socket.emit config.netMsg.game.start, {}, (success) =>
      console.log "Game start successful"

  $scope.lockIn = ->
    if !$scope.getMainPlayer().race
      $scope.showError("noRaceSelected")
      return false
    $scope.getMainPlayer().ready = true
    $scope.updateValue($scope.playerId, "ready")

  $scope.showError = (error, closeCallback = noop) ->
    modalName = error.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase();
    modal = $modal.open({templateUrl: 'templates/error-modals/' + modalName + '.html', scope: $scope})
    modal.result.then (-> closeCallback()), (-> closeCallback())
    console.log("Error: ", error)

  $scope.updateCountdownTimer = ->
    if $scope.timeRemaining
      $scope.countdownTimers = [$scope.timeRemaining - Math.floor((Date.now() - $scope.gameDetailsUpdateTime) / 1000)]

  $scope.$on "$destroy", ->
    if timer
      $interval.cancel(timer);

  $scope.viewLoaded = ->
    timer = $interval($scope.updateCountdownTimer, 1000)
    serverDetails = NetService.extractServerDetailsFromUrl(window.location.href);
    connect(serverDetails.host, serverDetails.port, serverDetails.code);
    setTimeout =>
      if @getTotalBots() < 1
        NetService.log("error", "No bots in custom game after 10 seconds server url: " + NetService.gameServer.host)
    , 10000

GameLobbyCtrl.$inject = ['$interval', '$location', '$modal', '$scope', '$rootScope', 'NetService', 'UserService', 'AnalyticsService', 'GoogleAnalyticsService']
window.GameLobbyCtrl = GameLobbyCtrl