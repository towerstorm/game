#global ts

Game = require("../engine/game.coffee")
Timer = require("../engine/timer.coffee")
Player = require("./modules/player.coffee")
PlayerManager = require("./modules/player-manager.coffee")
Cache = require("./modules/cache.coffee")
GameEntity = require("./entities/game-entity.coffee")
ModifierPool = require("./modifiers/modifier-pool.coffee")
CastleManager = require("./modules/castle-manager.coffee")
GemManager = require("./modules/gem-manager.coffee")
Hud = require("./modules/hud.coffee")
MinionManager = require("./modules/minion-manager.coffee")
TutorialManager = require("./modules/tutorial-manager.coffee")
TowerManager = require("./modules/tower-manager.coffee")
TickManager = require("./modules/tick-manager.coffee")
Dispatcher = require("./modules/dispatcher.coffee")
FPS = require("./modules/fps.coffee")

config = require("config/general")
mapConfig = require("../../../config/maps")
gameMsg = require("config/game-messages")

_ = require("lodash")

class PTGame extends Game

  constructor: ->
    @reset()
    super()
    ts.log.info("game init")

    @functions = require './functions.coffee'

    @config =
      gameMsg: window.config.gameMsg
      maps: window.config.maps
      races: window.config.races
      minions: window.config.minions
      bullets: window.config.bullets
      towers: window.config.towers
      general: window.config.general
      vfx: window.config.vfx

    @hardReset();
    @loadManagers();
    @loadLevel();


  ###
    * Soft reset called before start to reset the ticks back to normal as update() is running and incrementing ticks before the game is even started
  ###
  reset: ->
    ts.log.info("Doing soft reset")
    super()
    @map = null
    @mapBackground = null
    @paddingTop = 0
    @paddingLeft = 0
    @fps = null
    @cache = null
    @modPool = null
    @towerManager = null
    @minionManager = null
    @gemManager = null

    if @tickManager?
      @tickManager.tickQueue = {}
    @tickManager = null

    @dispatcher = null
    @lastTick = 0
    @currentHash = 0
    @statusText = null
    @hasEnded = false
    @winningTeam = null

    @lastTick = 0
    @state = "NONE"
    @settings = {}
    @currentRound = -1
    @roundStartTimerCountdown = 0
    @triggeredReady = false
    @ts = null
    @hud = null
    @debugMode = false
    @isFastForwarding = false
    @largeTickQueue = false
    @graphics = null
    @statusText = null
    @roundTime = 0
    @lastInnerWidth = 0
    @lastInnerHeight = 0
    ts.system.clock.reset()

  ###
   *  Resets the game back to initial values so we can play unlimited games without refreshing
  ###
  hardReset: ->
    ts.log.info("Resetting game")
    @reset();

    @state = config.states.init;
    @settings = {
      mapId: 0
      mode: config.modes.pvp,
      difficulty: 0
      targetTime: 0
      incomeMultiplier: 1
      linearGold: false
      seed: 912348123611
    }

    ts.log.info("Setting game state to: ", @state)
    @triggeredReady = false
    @loadDispatcher();
    @resetSystem();
    @resetManagers();

  ###
    Sets all managers back to their default nulled state.
    Load Managers should be called after this as init is not run on
    the managers in reset so initial config data has not been setup
    so they are not ready to use after a reset, just set back to what they would be
    if they were loaded from scratch again.
  ###
  resetManagers: ->
    if @playerManager then @playerManager.reset()
    if @towerManager then @towerManager.reset()
    if @minionManager then @minionManager.reset()
    if @hud then @hud.reset()
    if @gemManager then @gemManager.reset()
    if @tickManager then @tickManager.reset()
    if @castleManager then @castleManager.reset()
    if @tutorialManager then @tutorialManager.reset();
    if @cache then @cache.reset()
    if @modPool then @modPool.reset()

  loadManagers: ->
    # Initialize all the managers after the config is done.
    @playerManager = new PlayerManager(@dispatcher)
    @towerManager = new TowerManager()
    @minionManager = new MinionManager()
    @hud = new Hud(@dispatcher)
    @gemManager = new GemManager(@dispatcher)
    @tickManager = new TickManager()
    @castleManager = new CastleManager()
    @tutorialManager = new TutorialManager()
    @cache = new Cache()
    @modPool = new ModifierPool()
    @fps = new FPS()

  loadDispatcher: ->
    if @dispatcher?
      @dispatcher.reset();
    @dispatcher = new Dispatcher()
    @dispatcher.reset();
    @bindDispatcher();

  resetSystem: ->
    canvas = @getCanvas();
    if canvas?
      canvasDimensions = @getCanvasDimensions();
      ts.system.reset(canvasDimensions.width, canvasDimensions.height, canvasDimensions.scale)
      @resetGraphics()

  resetGraphics: ->
    if !PIXI?
      return false
    canvasDimensions = @getCanvasDimensions();
    if @graphics
      try
        ts.system.stage.removeChild(@graphics);
      catch e
        #Whatevs, pixi errors out if it doesn't have the child but we don't really care.
      delete @graphics;
    @graphics = new PIXI.Graphics();
    @graphics.zIndex = config.graphics.zIndex
    ts.system.container.addChild(@graphics);
    @graphics.position = new PIXI.Point(canvasDimensions.paddingLeft, canvasDimensions.paddingTop)


  bindDispatcher: ->
    @dispatcher.on gameMsg.start, =>
      @start();
    @dispatcher.on gameMsg.gameDetails, (data) =>
      @setGameDetails(data);
    @dispatcher.on gameMsg.tickData, (tick, data) =>
      @tickManager.addTick(tick, data);
    @dispatcher.on gameMsg.syncData, (lastTick, ticks) =>
      @fastForward lastTick, ticks, true
    @dispatcher.on gameMsg.pauseLogic, =>
      @pauseLogic(true)
    @dispatcher.on gameMsg.unpauseLogic, =>
      @unpauseLogic(true)
    @dispatcher.on gameMsg.castleDied, (castle) =>
      if castle.final
        winningTeam = if castle.team == 0 then 1 else 0
        @endAfterUpdate(winningTeam)

  setGameDetails: (data) ->
    for name, value of data
      if @settings[name] != undefined
        if ts.isNumber(value)
          value = parseFloat(value, 10);
        this.settings[name] = value
        @dispatcher.emit(gameMsg.gameDetailChanged, name, value)

  isTutorial: () ->
    return @settings.mode == config.modes.tutorial
    
  getPeaceTime: () ->
    return mapConfig[@settings.mapId].peaceTime || 0
    
  isInPeaceTime: () ->
    return ts.getCurrentConstantTime() < @getPeaceTime()
    
  canBuildAnything: () ->
    return mapConfig[@settings.mapId].canBuildAnything || false
    
  canAttackOwnMinions: () ->
    return mapConfig[@settings.mapId].canAttackOwnMinions || false

  loadMap: (mapId) ->
    @map = _.cloneDeep(mapConfig[mapId])
    @resetGraphics()
    @loadBackground(@map.background, @map.backgroundWidth, @map.backgroundHeight);

  loadBackground: (name, width, height) ->
    container = ts.system.container
    dimensions = @getCanvasDimensions()
    mapTexture = new PIXI.Texture.fromImage('/img/maps/' + name);
    mapSprite = new PIXI.Sprite(mapTexture);
    mapSprite.zIndex = 0
    mapSprite.x = (0 - dimensions.paddingLeft) - config.tileSize
    mapSprite.y = (0 - dimensions.paddingTop) -  config.tileSize
    container.addChildAt(mapSprite, 0);



  start: ->
    if @state != config.states.init
      return false;
    @state = config.states.started;
    ts.log.info( "In start setting game state to: ", @state)
    @loadMap(@settings.mapId)
    @loadLevel();
    @checkWindowSize();
    @hud.begin();
    @playerManager.begin();
    @towerManager.begin(@settings.mapId)
    @minionManager.begin(@settings.mapId)
    @castleManager.begin(@settings.mapId)
    @tutorialManager.begin();
    player = @playerManager.getMainPlayer()
    @update();

  end: (winningTeam) ->
    @doneTick() #Send the final tick to the clients before everything ends.
    ts.log.info("Ending game, winning team is: ", winningTeam, " players is: ", @players)
    @state = config.states.finished;
    ts.log.info("In end setting game state to: ", @state)
    ts.system.stopRunLoop()
    @hud.reset()
    @dispatcher.emit gameMsg.finished, winningTeam, ts.getCurrentTick()

  endAfterUpdate: (winningTeam) ->
    @hasEnded = true
    @winningTeam = winningTeam

  ###
  Gets a JSON object of everything happening in the game world at this point in time, done client side too then compared to ensure
  the clients and server are always in sync
  ###
  getGameSnapshot: ->
    gameState =
      players: @playerManager.getSnapshot()
      minionManager: @minionManager.getSnapshot()
      towerManager: @towerManager.getSnapshot()
    return gameState

  ###
  Gets a fast hash of the game state JSON object, to compare server and client quickly and ensure they are in sync.
  ###
  getGameSnapshotHash: (snapshot) ->
    snapshotString = JSON.stringify(snapshot)
#        ts.log.info "Snapshot tick: ", ts.getCurrentTick(),  " string: ",  snapshotString
    hash = ts.hashString(snapshotString);
    return hash;

  ###
   * Fast forwards the game processing many ticks at once in the update loop without rendering
   * this is mainly used when reconnecting to games to resync all the data and could be used
   * for catching up to the server too.
  ###
  fastForward: (toTickId, ticks, fromSync) ->
    if fromSync
      @lastTick = 0
    @isFastForwarding = true
    for own tick, tickData of ticks
      @tickManager.addTick(tick, tickData);
    initialTick = ts.getCurrentTick()
    @unpauseLogic();
    for i in [initialTick..toTickId]
      if !@tickManager.tickQueue[i]?
        @tickManager.tickQueue[i] = {}
    if fromSync && false #This is broken don't know why, added false to make it not run.
      processTick = (tickId) =>
        ts.setTick(tickId);
        if fromSync
          ts.system.calculateConstantTick()
        @update(true);
        if tickId % 50 == 0 || tickId == toTickId
          @dispatcher.emit gameMsg.syncProgressTick, tickId
        if tickId < toTickId
          setTimeout((=> processTick(++tickId)), 0) #So we don't hog all the CPU
#            processTick(++tickId)
        else
          @lastTick = tickId
          @fastForwardComplete()
      processTick(initialTick)
    else
      for i in [initialTick...toTickId]
        ts.addTick();
        if fromSync
          ts.system.calculateConstantTick()
        @update(true);
        if i % 25 == 0
          @dispatcher.emit gameMsg.syncProgressTick, i
      @dispatcher.emit gameMsg.syncProgressTick, toTickId
      @fastForwardComplete()

  fastForwardComplete: ->
    @isFastForwarding = false
    if @playerManager.getMainPlayer()
      @playerManager.getMainPlayer().playerUpdated()

  pauseLogic: (emitDisabled) ->
    if !emitDisabled? || !emitDisabled
      @dispatcher.emit gameMsg.pauseLogic
    super()

  unpauseLogic: (emitDisabled) ->
    if !emitDisabled? && !emitDisabled
      @dispatcher.emit gameMsg.unpauseLogic
    super();

  update: (fromFastforward) ->
    if @isFastForwarding && (!fromFastforward? || !fromFastforward)
      return false
    if !@triggeredReady
      @dispatcher.emit gameMsg.ready
    if @state != config.states.started
      return false
    currentTick = ts.getCurrentTick();
#        if @playerManager.checkForDeadPlayers(@playerManager.players)
#          return false #Return false if any dead players were found so we don't keep running and crash
    if @settings.mode == config.modes.tutorial || @tutorialManager.freePlayStarted == true
      @tutorialManager.update()
    @castleManager.update()
    @hud.update()
    @tickManager.processTick(currentTick)
    if !@logicPaused && currentTick > @lastTick #Don't logic loop more than once per tick.
      ts.log.debug("Processing tick " + currentTick + " fast forwarding: " + @isFastForwarding)
      @minionManager.update()
      @towerManager.update()
      @playerManager.update()
      ts.log.debug("End of main update loop")
      if @hasEnded
        @end(@winningTeam)
    super()

  # For running functions after the main update loop (after parent has done too)
  # For fast forwarding the game only for now but maybe other things later
  # This is called after tickdone
  postUpdate: ->
    if @isFastForwarding
      return false;
    currentTick = ts.getCurrentTick();
    tickNum = currentTick + 1;
    while @tickManager.tickQueue[tickNum]?
      tickNum++;
    totalTicksInQueue = tickNum - currentTick
    ticksBeforeFastForward = (config.timeBeforeFastForward / Timer.constantStep) # + @totalLogicPauses
    @largeTickQueue = totalTicksInQueue > ticksBeforeFastForward #largeTickQueue is a boolean that stops things from drawing so we can speed up the game without many bullets going off like crazy
    if currentTick == @lastTick && totalTicksInQueue >= ticksBeforeFastForward
      @fastForward(currentTick+1, null, false)

  getCanvasDimensions: ->
    if @getWindow()
      resX = @getWindow().innerWidth
      resY = @getWindow().innerHeight
    #Get the scale set in the frontend controller so we're not duplicating code.
    scale = @getWindow().tsScale || 1
    if ts.ua.pixelRatio?
      pixelRatio = ts.ua.pixelRatio
#          resX = resX / pixelRatio
#          resY = resY / pixelRatio
      scale *= pixelRatio
    paddingLeft = 0
    paddingTop = 0
    #if @map
      #paddingLeft = (resX - (@map.width * config.tileSize)) / 2
      #paddingTop = (resY - (@map.height * config.tileSize)) / 2
    #paddingTop += 40 #For info panel up top
#          paddingTop = ((resY - @map.backgroundHeight) / 2) +

    return {width: resX, height: resY, paddingLeft: paddingLeft, paddingTop: paddingTop, scale: scale}

  draw: ->
    if @state in [config.states.init, config.states.finished]
      return false;
    # Draw all entities and backgroundMaps
    super()
    @graphics.clear();
    @fps.update();
    @hud.draw();
    player = @playerManager.getMainPlayer()
    if player?
      textXPos = 400
      if window? && window.innerWidth && window.innerHeight
        textXPos = @getCanvasDimensions().width / 2
        if @isInPeaceTime()
          peaceTime = @getPeaceTime()
          timeTillStart = Math.floor(peaceTime - ts.getCurrentConstantTime())
          battleBeginsXPos = if @playerManager.getMainPlayer().getTeam() == 0 then textXPos + 55 else 60
          battleBeginsText = "Battle begins in\n" + timeTillStart + "\n Prepare your defenses!"
        else if ts.getCurrentConstantTime() < peaceTime + 5
          timeTillStart = Math.floor(peaceTime - ts.getCurrentConstantTime())
          battleBeginsText = "The battle has begun,\nsend your minions!\n"
        if battleBeginsText
          if @statusText
            @statusText.setText(battleBeginsText)
          else
            @statusText = @hud.drawText(battleBeginsText, battleBeginsXPos, 200)
        else if @statusText?
          ts.system.container.removeChild(@statusText)
          @statusText = null

#        if @debugMode
#          ticksBehindServer = 0; tickNum = @lastTick
#          while(@tickManager.tickQueue[tickNum++]?)
#            ticksBehindServer++
#          @hud.drawText("Ticks behind server: "+ticksBehindServer, textXPos, 190, "right")

  checkWindowSize: ->
    canvas = @getCanvas()
    if !canvas?
      return false
    if @getWindow()? && @getWindow().innerWidth && @getWindow().innerWidth != @lastInnerWidth && @getWindow().innerHeight && @getWindow().innerHeight != @lastInnerHeight
      @lastInnerWidth = @getWindow().innerWidth
      @lastInnerHeight = @getWindow().innerHeight
      dimensions = @getCanvasDimensions();
      @paddingLeft = dimensions.paddingLeft
      @paddingTop = dimensions.paddingTop
      #if canvas.offsetWidth != Math.floor(dimensions.width * dimensions.scale) || canvas.offsetHeight != Math.floor(dimensions.height * dimensions.scale)
      ts.system.resize(dimensions.width, dimensions.height, dimensions.scale)

  getCanvas: ->
    if @getWindow()? && @getWindow().document?
      return document.getElementById("canvas");
    return null

  #for testing
  getWindow: ->
    if window? && window.innerWidth && window.innerHeight
      return window

  doneTick: ->
    currentTick = ts.getCurrentTick()
    if @lastTick >= currentTick || @logicPaused || @state != config.states.started
      return false;
    # if currentTick % 100 == 0
      # console.log "Current game state tick ", currentTick, " is: ", JSON.stringify @getGameSnapshot();
    @dispatcher.emit @config.gameMsg.tickDone, currentTick, @tickManager.tickQueue[currentTick]
    if ts.getCurrentTick() % 10 == 1 || @debugMode
      snapshot = @getGameSnapshot()
      @dispatcher.emit @config.gameMsg.gameSnapshot, currentTick, snapshot, @getGameSnapshotHash(snapshot)
    @tickManager.removeTick(currentTick)
    @lastTick = currentTick
    @postUpdate();


module.exports = PTGame
