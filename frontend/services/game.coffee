###
  Handles all the core game stuff like figuring out the sidebar buttons, what ones are shown, sending packets to the server etc. Any code that is used for interacting with the canvas
  and should be shared between the main game controller and tutorial controller goes in here.
###
angular.module('gameService', ['ngResource']).factory('GameService', ['$resource', '$rootScope', 'AnalyticsService', 'NetService', 'UserService', ($resource, $rootScope, AnalyticsService, NetService, UserService) ->
  TICKS_BEFORE_RESYNC = 10
  TICK_REQUEST_THROTTLE_RATE_MS = 1000

  PIXI.AUTO_PREVENT_DEFAULT = false

  class GameService
    ts: null
    config: null
    socket: null
    resX: null
    resY: null
    scale: 1
    map: null
    chatRoomIds: {}
    player:
      canSendMinion: {}
      canSeeMinionButton: {}
      canPickTower: {}
      canSeeTowerButton: {}
      minionCounts: {}
      minionExperienceOverlayWidth: {}
      minionRespawnOverlayHeight: {}
    minionButtons: [],
    towerButtons: [],
    timeSurvived: 0,
    lastTrackedTime: 0,
    lastPlayerUpdate: 0,
    syncFinalTick: 0,
    hasConnected: false
    hasGameLoaded: false
    hasAssetsLoaded: false
    hasSynced: true
    didWin: null
    highlighted:
      tower: null
      minion: null
    infoPanel:
      xPos: 0
      yPos: 0
      title: ""
      text: ""
      visible: false
    towerPanel:
      title: ""
      stats: {}
      nextLevelStats: {}
      upgradeCost: 0
      sellValue: 0
      visible: false
    helperText: null
    ctx: null
    tickRequestTimes: {}

    init: (@ts, @config) =>
      @reset()
      @resX = @config.general.gameWidth
      @resY = @config.general.gameHeight
      ts.system.startRunLoop();
      @scale = @calculateScale();
      @initZooming();
      @addDragNDrop();
      $rootScope.$broadcast('game.ts.loaded')

    ###
      Resets back to intial state, as gameController constructor only ever runs once when the browser is reloaded not every time
      a new game is started. This is resetting for a new game.
    ###
    reset: () =>
      if @socket
        @socket.disconnect()
      @socket = null
      @map = null
      @player = {
        canSendMinion: {}
        canSeeMinionButton: {}
        canPickTower: {}
        canSeeTowerButton: {}
        minionCounts: {}
        minionRespawnOverlayHeight: {}
      }
      @minionButtons = []
      @towerButtons = []
      @timeSurvived = 0
      @lastTrackedTime = 0
      @lastPlayerUpdate = 0
      @hasConnected = false
      @hasGameLoaded = false
      @hasAssetsLoaded = false
      @hasSynced = true
      @highlighted = {
        tower: null
        minion: null
      }
      @infoPanel = {
        xPos: 0
        yPos: 0
        title: ""
        text: ""
        visible: false
      }
      @towerPanel = {
        title: ""
        stats: {}
        nextLevelStats: {}
        upgradeCost: 0
        sellValue: 0
        visible: false
      }
      @helperText = null
      @ctx = {
        global: { x: 0, y: 0}
      }
      @tickRequestTimes = {}

    connect: (host, port, code) =>
      if !@socket? and typeof io isnt "undefined"
        @socket = io.connect("//" + host + ":" + port + @config.netMsg.game.path + "/" + code, {
          'reconnect': true,
          'reconnection delay': 500,
          'max reconnection attempts': 10
        })
      @postConnect();

    postConnect: =>
      @bindDispatcher()
      @bindSockets()
      @overloadEngine();

    log: =>

    overloadEngine: =>
      formatLog = =>
        logPieces = []
        for piece in arguments
          if typeof piece == "object"
            logPieces.push(JSON.stringify(piece))
          else
            logPieces.push(piece)
        return logPieces.join(" ")

      @ts.log.info = () =>
        log = formatLog.apply(this, arguments)
        console.log log

#      @ts.log.debug = () =>
#        log = formatLog.apply(this, arguments)
#        console.log log
#        args = Array.prototype.slice.call(arguments, 0)
#        args.unshift(@ts.getCurrentTick() + ": ")
#        log = formatLog.apply(this, args)
#        @socket.emit(@config.netMsg.player.log.debug, log)

      @ts.getLogs = =>
        return @ts.logs;

    initZooming: =>
      addWheelListener document, (e) =>
        @zoom(e.clientX, e.clientY, if e.deltaY < 0 then -0.1 else 0.1);
      addPinchListener ts.system.view, (e) =>
        @zoom(e.x, e.y, e.delta / 200);

    zoom: (x, y, delta) ->
      factor = (1 + (0-delta));
      container = ts.system.container
      container.scale.x = Math.max(0.2, Math.min(3, container.scale.x * factor));
      container.scale.y = Math.max(0.2, Math.min(3, container.scale.y * factor));

      beforeTransform = this.getGraphCoordinates(x, y);
      container.updateTransform();
      afterTransform = this.getGraphCoordinates(x, y);

      container.position.x += (afterTransform.x - beforeTransform.x) * container.scale.x;
      container.position.y += (afterTransform.y - beforeTransform.y) * container.scale.y;
      container.updateTransform();

    getGraphCoordinates: (x, y) =>
        @ctx.global.x = x; @ctx.global.y = y;
        return PIXI.InteractionData.prototype.getLocalPosition.call(@ctx, ts.system.container);

    addDragNDrop: =>
      self = @
      stage = ts.system.stage;
      container = ts.system.container
      stage.setInteractive(true);

      isDragging = false
      prevX = null
      prevY = null


      mousedown = (moveData) ->
        if self.isTouchDevice() && ts.game.hud.pickedTower then return;

        pos = moveData.global;
        prevX = pos.x; prevY = pos.y;
        isDragging = true;

      mousemove = (moveData) ->
        if !isDragging then return;

        pos = moveData.global;
        dx = pos.x - prevX;
        dy = pos.y - prevY;

        if ((Math.abs(dx) + Math.abs(dy)) > 100) && self.isTouchDevice()
          return;

        container.position.x += dx;
        container.position.y += dy;
        prevX = pos.x; prevY = pos.y;

      mouseup = (moveDate) ->
        isDragging = false;

      stage.mousedown = mousedown
      stage.mousemove = mousemove
      stage.mouseup = mouseup
      stage.touchstart = mousedown
      stage.touchmove = mousemove
      stage.touchend = mouseup

    getPixelRatio: =>
      devicePixelRatio = 1;
      if 'devicePixelRatio' in window
        devicePixelRatio = window.devicePixelRatio
      return devicePixelRatio;

    calculateScale: =>
      return 1 #TODO: Figure out if game *should* scale down on smaller screens or just scroll around
      widthHeightRatio = @resX / @resY;
      sidebarIconSize = @getSidebarSize();
      maxWidth = window.innerWidth - sidebarIconSize * 2
      gameWidth = Math.min(window.innerHeight * widthHeightRatio, maxWidth);
      scale = (gameWidth / @resX);
      scale = Math.floor(scale * 10) / 10; # Round to nearest 0.1 as otherwise game art goes screwy.
      scale = Math.min(scale, 1); #Don't want it to be greater than 1 for now.
      return scale

    isTouchDevice: =>
      return !!('ontouchstart' of window) || !!('onmsgesturechange' of window);

    getSidebarSize: =>
      iconSize = 40
      if window.innerHeight >= 600
        iconSize = 100
      else if window.innerHeight >= 480
        iconSize = 80
      else if window.innerHeight >= 360
        iconSize = 60
      return iconSize

    getSidebarMinionSpacing: =>
      minionSpacing = (@getPlayFieldSize().height - @getSidebarSize() * 6) / 7
      return minionSpacing

    getSidebarOffset: =>
      if !@map
        return 0
      width = @map.width * 48
      height = @map.height * 48
      offset = {
        x: Math.max(0, (((window.innerWidth - width) / 2) - @getSidebarSize()) - 10) #-10 because it looks better not butted up against the edge
        y: Math.max(0, ((window.innerHeight - height) / 2))
      }
      return offset


    getPlayFieldSize: =>
      width = @config.general.gameWidth * @calculateScale()
      height = @config.general.gameHeight * @calculateScale()
      paddingTop = (ts.game.paddingTop || 0) * @calculateScale()
      return {width, height, paddingTop}

    getGameWrapperSize: =>
      height = window.innerHeight
      if @isTouchDevice()
        width = window.innerWidth
      else
        width = @getPlayFieldSize().width + @getSidebarSize() * 2
      return {width, height}

    bindDispatcher:  =>
      @ts.game.dispatcher.on @config.gameMsg.ready, =>
        @gameLoaded();
      @ts.game.dispatcher.on @config.gameMsg.syncProgressTick, (tick) =>
        @syncProgress(tick);
      @ts.game.dispatcher.on @config.gameMsg.gameSnapshot, (tick, gameSnapshot, gameSnapshotHash) =>
        @gameSnapshot(tick, gameSnapshot, gameSnapshotHash)
      @ts.game.dispatcher.on @config.gameMsg.action.placeTower, (xCoord, yCoord, towerType) =>
        @placeTower(xCoord, yCoord, towerType)
      @ts.game.dispatcher.on @config.gameMsg.action.upgradeTower, (settings) =>
        @upgradeTower(settings)
      @ts.game.dispatcher.on @config.gameMsg.action.sellTower, (settings) =>
        @sellTower(settings)
      @ts.game.dispatcher.on @config.gameMsg.action.placeMinion, (xCoord, yCoord, minionType) =>
        @placeMinion(xCoord, yCoord, minionType)
      @ts.game.dispatcher.on @config.gameMsg.action.collectGem, (gemId) =>
        @collectGem(gemId)
      @ts.game.dispatcher.on @config.gameMsg.finished, (winningTeam, lastTick) =>
        @endGame(winningTeam, lastTick);
      @ts.game.dispatcher.on @config.gameMsg.playerUpdated.all, (player) =>
        @updatePlayerInfo(player);
      @ts.game.dispatcher.on @config.gameMsg.playerUpdated.gold, (player) =>
        @updatePlayerGold(player);
      @ts.game.dispatcher.on @config.gameMsg.playerUpdated.income, (player) =>
        @updatePlayerIncome(player);
      @ts.game.dispatcher.on @config.gameMsg.playerUpdated.souls, (player) =>
        @updatePlayerSouls(player);
      @ts.game.dispatcher.on @config.gameMsg.playerUpdated.minions, (player) =>
        @updatePlayerMinions(player);
      @ts.game.dispatcher.on @config.gameMsg.highlightButton, (type, subType) =>
        @highlightButton(type, subType)
      @ts.game.dispatcher.on @config.gameMsg.showInfoPanel, (title, text, buttons, options) =>
        @showInfoPanel(title, text, buttons, options)
      @ts.game.dispatcher.on @config.gameMsg.hideInfoPanel, () =>
        @hideInfoPanel();
      @ts.game.dispatcher.on @config.gameMsg.showTowerPanel, (title, team, level, stats, modifiers, auras, upgradeCost, sellValue) =>
        @showTowerPanel(title, team, level, stats, modifiers, auras, upgradeCost, sellValue)
      @ts.game.dispatcher.on @config.gameMsg.hideTowerPanel, () =>
        @hideTowerPanel();
      @ts.game.dispatcher.on @config.gameMsg.showHelperText, (text) =>
        @showHelperText(text);
      @ts.game.dispatcher.on @config.gameMsg.hideHelperText, () =>
        @hideHelperText();
      @ts.game.dispatcher.on @config.gameMsg.startTutorialStep, (stepId) =>
        AnalyticsService.track('StartTutorialStep - ' + stepId)
      @ts.game.dispatcher.on @config.gameMsg.endTutorialStep, (stepId) =>
        AnalyticsService.track('EndTutorialStep - ' + stepId)
      @ts.game.dispatcher.on @config.gameMsg.previousTutorialStep, (stepId) =>
        AnalyticsService.track('PreviousTutorialStep - ' + stepId)
      @ts.game.dispatcher.on @config.gameMsg.finishTutorial, () =>
        AnalyticsService.track('FinishedTutorial', {})
      @ts.game.dispatcher.on @config.gameMsg.pauseLogic, () =>
        tick = @ts.getCurrentTick()
        AnalyticsService.track('GamePaused', {tick})
      @ts.game.dispatcher.on @config.gameMsg.unpauseLogic, () =>
        tick = @ts.getCurrentTick()
        AnalyticsService.track('GameUnpaused', {tick})
      window.tsloader.onComplete () =>
        @assetsLoaded()

    sendPing: =>
      console.log "Sent ping at " + Date.now();
      @socket.emit "ping", (response) =>
        console.log "Recieved " + response + " at " + Date.now();
      setTimeout((=> @sendPing()), 1000);

    bindSockets: =>
      @socket.on @config.netMsg.player.details, (details) =>
        @clientConnected(details)
      @socket.on @config.netMsg.disconnect, =>
        @showDisconnectedScreen();
      @socket.on @config.netMsg.game.details, (details) =>
        #console.log("Got game details: ", details)
        @updateDetails(details)
      @socket.on @config.netMsg.game.begin, (details) =>
        @beginGame(details)
      @socket.on @config.netMsg.game.syncData, (lastTick, data) =>
        @processSyncData(lastTick, data)
      @socket.on @config.netMsg.game.tickData, (tick, data, callback) =>
        @processTickData(tick, data, callback)
        @checkTickNeeded(tick)
      @socket.on @config.netMsg.player.pingTime, (ping) =>
        @ts.game.dispatcher.emit @config.gameMsg.getMainPlayer, (player) =>
          if player?
            player.setPing(ping);

    gameLoaded: =>
      @hasGameLoaded = true
      @reportReady()

    assetsLoaded: =>
      @hasAssetsLoaded = true
      @reportReady()

    checkAssetsLoaded: =>
      if @hasAssetsLoaded
        return true
      if window.tsloader && window.tsloader.pxFinished && window.tsloader.pixiFinished
        return true
      return false
      
    isPlayerReady: =>
      if !@hasConnected
        console.log("Player has not connected")
        return false
      if !@hasGameLoaded
        console.log("Player has not loaded the game")
        return false
      if !@checkAssetsLoaded() 
        console.log("Player has not loaded assets")
        return false
      if !@hasSynced
        console.log("Player has not synced")
        return false
      return true

    reportReady: =>
      if !@isPlayerReady()
        return false
      ts.game.triggeredReady = true
      setTimeout((=> @socket.emit(@config.netMsg.player.loaded)), 2000);
      #console.log "Player has loaded"
      $rootScope.$broadcast('game.player.loaded')
      AnalyticsService.track("Loaded game assets")

    gameSnapshot: (tick, gameSnapshot, gameSnapshotHash) =>
      @socket.emit @config.netMsg.game.checkHash, tick, gameSnapshotHash, (data) =>
        returnData = JSON.parse data
        if returnData.ok == false && !@hashIncorrect
          @hashIncorrect = true;
          AnalyticsService.track("Hash is incorrect", {tick: tick})
          @reportInvalidGameState tick, gameSnapshot, (err, data) =>
            if window.location.href.match(/ts.dev/)
              throw new Error("Hash incorrect")
            else
              location.reload(); #Refresh the page.


    reportInvalidGameState: (tick, snapshot, callback) =>
      gameDetails = NetService.extractServerDetailsFromUrl(window.location.href);
      code = gameDetails.code
      path = "//" + gameDetails.host + ":" + gameDetails.port + "/game/desync/" + code + "/"
      data = {tick: tick, gameSnapshot: snapshot}
#      NetService.gamePost("/game/desync/" + code + "/", {tick: tick, gameSnapshot: snapshot}, callback)
      AnalyticsService.track("Player desynced")
      NetService.log 'error', 'Player desynced', ->
        NetService.sendData('POST', path, data, callback)

    placeTower: (xCoord, yCoord, towerType) =>
      AnalyticsService.track("Placed tower", {x: xCoord, y: yCoord, towerType});
      @socket.emit @config.netMsg.game.placeTower, xCoord, yCoord, towerType

    unpickTower: =>
      ts.game.dispatcher.emit config.gameMsg.unpickTower
      $rootScope.$broadcast('game.unpickTower')

    unpickMinion: =>
      ts.game.dispatcher.emit config.gameMsg.unpickMinion
      $rootScope.$broadcast('game.unpickMinion')

    upgradeTower: (settings) =>
      @socket.emit @config.netMsg.game.upgradeTower, settings

    sellTower: (settings) =>
      @socket.emit @config.netMsg.game.sellTower, settings

    placeMinion: (xCoord, yCoord, minionType) =>
      AnalyticsService.track("Sent minion", {type: minionType})
      @socket.emit @config.netMsg.game.placeMinion, xCoord, yCoord, minionType

    collectGem: (gemId) =>
      AnalyticsService.track("Collected gem");
      @socket.emit @config.netMsg.game.collectGem, gemId

    #Updates the interface based on changes to the player, so shows new gold / health etc and disables buttons that the player doesn't have enough gold for.
    updatePlayerInfo: (player) =>
      @player.team = player.getTeam()
      @updatePlayerGold(player)
      @updatePlayerIncome(player)
      @updatePlayerSouls(player)
      @updatePlayerMinions(player)
      $rootScope.$broadcast('game.player.update', @player)

    updatePlayerGold: (player) =>
      @player.gold = Math.floor(player.getGold());
      @updateAvailableTowers(player)
      @updateAvailableMinions(player)
      $rootScope.$broadcast('game.gold.update', @player.gold)

    updatePlayerIncome: (player) =>
      @player.income = parseFloat((Math.round(player.getIncome() * 100) / 100).toPrecision(4));
      $rootScope.$broadcast('game.income.update', @player.income)

    updatePlayerSouls: (player) =>
      @player.souls = player.getSouls()
      @updateAvailableTowers(player)
      @updateAvailableMinions(player)
      $rootScope.$broadcast('game.souls.update', @player.souls)

    updateAvailableTowers: (player) =>
      towerButtonStates = {canPickTower: {}, canSeeTowerButton: {}}
      for type, tower of @config.towers
        towerButtonStates.canPickTower[type] = player.canPickTower(type)
        towerButtonStates.canSeeTowerButton[type] = player.canSeeTowerButton(type)
      $rootScope.$broadcast('game.towerButtonStates.update', towerButtonStates)

    updateAvailableMinions: (player) =>
      minionButtonStates = {canSendMinion: {}, canSeeMinionButton: {}}
      for button in @minionButtons
        type = button.minionType
        minionButtonStates.canSendMinion[type] = player.canSendMinion(type, false)
        minionButtonStates.canSeeMinionButton[type] = player.canSeeMinionButton(type)
      $rootScope.$broadcast('game.minionButtonStates.update', minionButtonStates)

    updatePlayerMinions: (player) =>
      for button in @minionButtons
        button.name = @config.minions[button.minionType].name
        button.cost = player.getMinionCost(button.minionType)
        button.income = player.getMinionIncome(button.minionType)
        button.health = player.getMinionHealth(button.minionType)
        button.speed = player.getMinionSpeed(button.minionType)
      $rootScope.$broadcast('game.minionButtons.update', @minionButtons)

    calculateRespawnOverlaySize: (refreshStartTick, refreshTime) ->
      if refreshStartTick == 0
        return 0
      refreshTimeInTicks = refreshTime / ts.Timer.constantStep
      currentTick = ts.getCurrentTick();
      percentPassed = (currentTick - refreshStartTick) / refreshTimeInTicks
      return Math.floor(percentPassed * 100)

    highlightButton: (type, subType) =>
      @highlighted[type] = subType
      $rootScope.$broadcast('game.highlighted.update', @highlighted);

    clientConnected: (details) =>
      @hasConnected = true;
      if details.sync == true && !@syncFinalTick  #If the player needs a sync and hasn't started receiving syncData yet (syncFinalTick)
        @hasSynced = false
        $rootScope.$broadcast('game.sync.needed');
      AnalyticsService.track("Authenticated in game")
      @reportReady();
      @hideDisconnectedScreen()

    processSyncData: (finalTick, data) =>
      if !data.playerId? || !data.players?
        console.error("Got sync data but it was missing playerId and/or players")
      @beginGame data
      delete data.playerId
      delete data.players
      @syncFinalTick = finalTick
      @ts.game.dispatcher.emit @config.gameMsg.syncData, finalTick, data.ticks

    syncProgress: (currentTick) =>
      percentProgress = Math.round((currentTick / @syncFinalTick) * 100)
      @hasSynced = percentProgress >= 100
      $rootScope.$broadcast('game.sync.progress', percentProgress)


    processTickData: (tick, data, callback) =>
#      if JSON.stringify(data) != "{}"
      #console.log("Received tick ", tick, " data: ", data)
      @ts.game.dispatcher.emit @config.gameMsg.tickData, tick, data
      $rootScope.$broadcast('game.time.update', Math.round(@ts.getCurrentConstantTime()))
      if callback?
        callback()

    checkTickNeeded: (tick) =>
      if !ts.game.tickManager.tickQueue[ts.getCurrentTick()] && tick > ts.getCurrentTick() + TICKS_BEFORE_RESYNC && ts.game.state != @config.general.states.finished
        pausedAtTick = ts.getCurrentTick()
        if !@tickRequestTimes[pausedAtTick] || @tickRequestTimes[pausedAtTick] < (Date.now() - TICK_REQUEST_THROTTLE_RATE_MS)
          @tickRequestTimes[pausedAtTick] = Date.now();
          @socket.emit @config.netMsg.game.tickNeeded, pausedAtTick


    hideDisconnectedScreen: =>
      console.log "You reconnected to the game :D"

    showDisconnectedScreen: =>
      console.log "You disconnected from the game :("

    updateDetails: (details) =>
      @players = details.players
      @chatRoomIds = details.chatRoomIds
      $rootScope.$broadcast('game.players.update', @players)
      $rootScope.$broadcast('game.details.update')


    beginGame: (details) =>
      settings = details.settings
      @setMap(settings.mapId)
      @ts.game.dispatcher.emit @config.gameMsg.gameDetails, settings
      @ts.game.dispatcher.emit @config.gameMsg.setPlayers, details.players
      @ts.game.dispatcher.emit @config.gameMsg.setMainPlayerId, details.playerId
      AnalyticsService.track("Starting game", details.players)
      @ts.game.dispatcher.emit @config.gameMsg.getMainPlayer, (player) =>
        playerTowers = player.race.towers
        if settings.mode == "SANDBOX"
          playerTowers = @config.towers
          playerTowers = Object.keys(playerTowers).map((key) -> return playerTowers[key].id);
        @createTowerButtons(playerTowers);
        @createMinionButtons(settings);
        @ts.game.start();
        $rootScope.$broadcast('game.start')

    endGame: (winningTeam, lastTick) =>
      @socket.emit @config.netMsg.player.finished, winningTeam, lastTick
      delete @socket
      @socket = null;
      @didWin = winningTeam == @player.team
      AnalyticsService.track("Ending Game", {didWin: @didWin})
      $rootScope.$broadcast('game.end')


    setMap: (mapId) =>
      if mapId? && @config.maps[mapId]?
        @map = @config.maps[mapId]
        @resX = @map.width * 48
        @resY = @map.height * 48
        $rootScope.$broadcast('game.map.info', @config.maps[mapId])

    ###
     * Sets up the buttons for building towers on the side of the screen
     *
    ###
    createTowerButtons: (towerNames) =>
      @towerButtons = []
      createButton = (name, settings) =>
        imagePosScale = 1
        @towerButtonsUrl = "/img/towerButtons.png"
        towerButton =
          cost: settings.cost
          towerType: name,
        if settings.imageName?
          towerButton.url = "/img/tower-icons/" + settings.id + ".png"; #Convert camel case to dashes
          towerButton.imagePosX = 0
          towerButton.imagePosY = 0
        else
          towerButton.url = @towerButtonsUrl
          towerButton.imagePosX = (settings.imageNum % 8 * (64 * imagePosScale))
          towerButton.imagePosY = (64 * imagePosScale) + ((settings.imageNum - (settings.imageNum % 8)) / 8) * (128 * imagePosScale)
        @towerButtons.push(towerButton)
      for towerName in towerNames
        button = createButton(towerName, @config.towers[towerName])
      $rootScope.$broadcast('game.towerButtons.update', @towerButtons)


    createMinionButtons: (gameSettings) =>
      @minionButtons = [];
      buttonNum = 0;
      createButton = (minion, player) =>
        imagePosScale = 1
        minionButton = {
          num: ++buttonNum
          name: minion.name
          health: player.getMinionHealth(minion.minionType)
          cost: player.getMinionCost(minion.minionType)
          income: player.getMinionIncome(minion.minionType)
          speed: player.getMinionSpeed(minion.minionType)
          moveType: minion.moveType
          armor: minion.armor
          magicResist: minion.magicResist
          minionType: minion.minionType
          availableCount: 5
          url: "/img/minion-icons/" + minion.minionType.replace(/([a-z])([A-Z])/g, '$1-$2').toLowerCase() + ".png" #Convert camel case to dashes
        };
        @minionButtons.push(minionButton);
      allowedRaces = []
      #Get the race of each of the main players allies and you can only send minions of each of those races.
      @ts.game.dispatcher.emit @config.gameMsg.getMainPlayer, (mainPlayer) =>
        for own name, minion of @config.minions
          if mainPlayer.minionValidForPlayer(minion.minionType)
            button = createButton(minion, mainPlayer)
        $rootScope.$broadcast('game.minionButtons.update', @minionButtons)

    showInfoPanel: (title, text, buttons, options) =>
      width = Math.floor(384 * @scale)
      height = Math.floor(273 * @scale)
      xPos = Math.floor(@resX * @scale - width)
      if options.team == 1
        xPos = 0
      xPos += ts.game.paddingLeft
      yPos = Math.floor(@resY * @scale - height + ts.game.paddingTop)
      @infoPanel = {width, height, xPos, yPos, title, text, visible: true, buttons}
      $rootScope.$broadcast('game.infoPanel.update', @infoPanel)
      $rootScope.$broadcast('game.infoPanel.visible', true)

    hideInfoPanel: () =>
      @infoPanel.visible = false
      $rootScope.$broadcast('game.infoPanel.visible', false)

    showTowerPanel: (title, team, level, stats, modifiers, auras, upgradeCost, sellValue) =>
      width = Math.floor(384 * @scale)
      height = Math.floor(273 * @scale)
      xPos = Math.floor(@resX * @scale - width)
      if team == 1
        xPos = 0
      xPos += ts.game.paddingLeft
      yPos = Math.floor(@resY * @scale - height + ts.game.paddingTop)
      @towerPanel = {width, height, xPos, yPos, title, level, stats, modifiers, auras, upgradeCost, sellValue, visible: true}
      $rootScope.$broadcast('game.towerPanel.update', @towerPanel)
      $rootScope.$broadcast('game.towerPanel.visible', true)

    hideTowerPanel: () =>
      $rootScope.$broadcast('game.towerPanel.visible', false)

    showHelperText: (text) =>
      @helperText = text
      $rootScope.$broadcast('game.helperText.update')

    hideHelperText: () =>
      @helperText = null
      $rootScope.$broadcast('game.helperText.update')

    clickInfoPanelButton: =>
      @ts.game.dispatcher.emit @config.gameMsg.clickInfoPanelButton







  return new GameService
]);
