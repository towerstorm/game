SandboxCtrl = ($scope, $location, $routeParams, AnalyticsService, GameService, GoogleAnalyticsService, NetService, UserService) ->
  $scope.backgroundUrl = null;
  $scope.pickedTower = null;
  $scope.player = {};
  $scope.gold = 0;
  $scope.income = 0;
  $scope.scale = 1;
  $scope.playField = {width: 0, height: 0}
  $scope.gameWrapper = {width: 0, height: 0}
  $scope.highlighted = {tower: null, minion: null}
  $scope.infoPanels = []
  $scope.players = []
  $scope.menuVisible = false
  $scope.loaded = false
  $scope.started = false
  $scope.endScreenImage = null
  $scope.screenPadding = 100

  $scope.viewLoaded = ->
    window.startTS = true;
    window.initGame();
    $scope.init();

  $scope.init = =>
    UserService.onUserLoad ->
      NetService.createGame {mode: "SANDBOX"}, (err, details) ->
        if err
          console.log("Failed to create game, err is: ", err);
        if details?
          setupGame details.server, 8082, details.code, ->
            initConnection details.server, 8082, details.code
  
  setupGame = (host, port, code, callback) ->
    connectUrl = "//" + host + ":" + port + "/game/" + code
    $scope.socket = io.connect(connectUrl, {'force new connection': true})
    $scope.socket.on config.netMsg.clientConnect, ->
      $scope.socket.on config.netMsg.player.details, (details) ->
        $scope.socket.emit config.netMsg.game.start, {}, (success) =>
          configChange = {race: 'crusaders', team: 0, ready: true}
          $scope.socket.emit config.netMsg.player.configure, configChange, (success) ->
            callback()
    
    
  initConnection = (host, port, code) =>
    console.log "In Init"
    window.devicePixelRatio = 2
    if !ts.game?
      return setTimeout((=> $scope.init()), 50)
    console.log "Engine has loaded"
    $scope.ts = ts
    GameService.init(ts, window.config)
    AnalyticsService.track("Initialized game")
    $scope.scale = GameService.calculateScale()
    window.tsScale = $scope.scale;
    $scope.pixelRatio = GameService.getPixelRatio()
    window.tsPixelRatio = $scope.pixelRatio;
    console.log "Extracted server details " + host + " " + port + " " + code
    GameService.connect(host, port, code);
    console.log "Connected to game"
    $scope.resizeLayout();
    $scope.bindButtons();
    $scope.bindDispatcher();
    console.log "Done init"
    document.ontouchmove = (event) ->
      event.preventDefault()


  $scope.resizeLayout = =>
    $scope.playField = GameService.getPlayFieldSize()
    $scope.gameWrapper = GameService.getGameWrapperSize()
    $scope.sidebar = {width: GameService.getSidebarSize(), minionSpacing: GameService.getSidebarMinionSpacing(), offset: GameService.getSidebarOffset()}

  $scope.bindButtons = =>
    $scope.clickInfoPanelButton = =>
      GameService.clickInfoPanelButton()

  $scope.unpickAll = ->
    GameService.unpickTower()
    GameService.unpickMinion()

  $scope.showMenu = =>
    $scope.menuVisible = true

  $scope.hideMenu = =>
    $scope.menuVisible = false

  $scope.safeApply = (fn) ->
    phase = @$root.$$phase
    if phase is "$apply" or phase is "$digest"
      fn()  if fn and (typeof (fn) is "function")
    else
      @$apply fn

  $scope.bindDispatcher = =>
    $scope.$on 'game.map.info', (e, mapInfo) ->
      $scope.backgroundUrl = mapInfo.background
      $scope.backgroundWidth = mapInfo.backgroundWidth
      $scope.backgroundSizePercent = $scope.calculateBackgroundSizePercent()
      $scope.backgroundPosX = (window.innerWidth - mapInfo.backgroundWidth) / 2
      $scope.backgroundPosY = ((window.innerHeight - mapInfo.backgroundHeight) / 2) + 40 #+40 for top bar
      $scope.resizeLayout()
      $scope.safeApply()
    $scope.$on 'game.player.update', ->
      $scope.player = GameService.player
      $scope.updateChat(GameService.chatRoomIds)
      $scope.safeApply()
    $scope.$on 'game.details.update', ->
      $scope.updateChat(GameService.chatRoomIds)
      $scope.safeApply()
    $scope.$on 'game.player.loaded', ->
      $scope.loaded = true
      $scope.safeApply()
    $scope.$on 'game.start', ->
      $scope.started = true
      $scope.safeApply()
    $scope.$on 'game.end', ->
      $scope.showEndScreen(GameService.didWin)
      $scope.safeApply()
    $scope.$on 'game.infoPanel.update', ->
      $scope.infoPanels = []
      $scope.infoPanels.push(GameService.infoPanel)
      $scope.safeApply()
    $scope.$on 'game.players.update', ->
      $scope.players = GameService.players
      $scope.safeApply()
    $scope.$on 'game.helperText.update', ->
      $scope.helperText = GameService.helperText
      $scope.safeApply()

  $scope.updateChat = (chatRoomIds) =>
    if chatRoomIds
      if chatRoomIds['team'+$scope.player.team]
        $scope.chatRoomId = chatRoomIds['team'+$scope.player.team]

  $scope.calculateBackgroundSizePercent = =>
    fullPlayFieldSize = $scope.playField.width / $scope.scale
    backgroundRatio = $scope.backgroundWidth / fullPlayFieldSize
    wantedBackgroundWidth = $scope.playField.width * backgroundRatio
    widthToOverallPercent = wantedBackgroundWidth / window.innerWidth;
    finalPercent = Math.floor(widthToOverallPercent * 10000) / 100
    return finalPercent;

  $scope.isTouchDevice = =>
    ua = navigator.userAgent.toLowerCase()
    return ua.indexOf("Android") > -1 || ua.indexOf("iPhone") > -1 || ua.indexOf("iPad") > -1

  $scope.showEndScreen = (didWin) ->
    $scope.gameEndResult = if didWin then "Victory" else "Defeat"
    GameService.didWin = didWin
    AnalyticsService.track("Game finished", {didWin: didWin});
    $scope.$apply()

  $scope.quit = ->
    $scope.loadGameSummary();

  $scope.loadGameSummary = ->
    $location.path('/game/summary/' + $routeParams.server + '/' + $routeParams.code).replace();



SandboxCtrl.$inject = ['$scope', '$location', '$routeParams', 'AnalyticsService', 'GameService', 'GoogleAnalyticsService', 'NetService', 'UserService']
window.SandboxCtrl = SandboxCtrl

