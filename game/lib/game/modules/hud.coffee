KEY = require("../../engine/keys.coffee")

GameEntity = require("../entities/game-entity.coffee")
config = require("config/general")
gameMsg = require("config/game-messages")
minionConfig = require("config/minions")
towerConfig = require("config/towers")

_ = require("lodash")

class Hud

  constructor: (dispatcher) ->
    @reset()
    @bindDispatcher(dispatcher);
    lastTouch = null;
    if document?
      @document = document;
    
  reset: ->
    @towerOverlay = null;
    @pickedTower = null;
    @lastTouch = null
    @fogCanvas = null
    @debugCanvas = null
    @debugHelpers = []
    @selectedEntity = null
    @lastClick = null
    @messageBuffer = []
    @document = null
    @fogOfWarOpacity = 0.2
    @quadTree = null
    @highlightedPosition = null
    @highlightedArea = null
    if ts.input?
      ts.input.unbindAll()
      ts.input.isUsingMouse = false;
      ts.input.isUsingKeyboard = false;

  begin: ->
    @bindKeys();

  bindDispatcher: (dispatcher) ->
    dispatcher.on gameMsg.pickTower, (towerType) =>
      @pickTower towerType
    dispatcher.on gameMsg.unpickTower, () =>
      @pickTower false
    dispatcher.on gameMsg.pickMinion, (minionType) =>
      @pickMinion minionType
    dispatcher.on gameMsg.unpickMinion, () =>
      @pickMinion false
    dispatcher.on gameMsg.entityHover, (entity) =>
      @entityHover(entity)
    dispatcher.on gameMsg.entityClicked, (entity) =>
      @entityClicked(entity)
    dispatcher.on gameMsg.highlightPosition, (details) =>
      @highlightPosition(details)
    dispatcher.on gameMsg.highlightArea, (details) =>
      @highlightArea(details)
    dispatcher.on gameMsg.upgradeSelectedTower, () =>
      @upgradeSelectedTower()
    dispatcher.on gameMsg.sellSelectedTower, () =>
      @sellSelectedTower()
    dispatcher.on gameMsg.upgradedTower, (tower) =>
      @upgradedTower(tower)
    dispatcher.on gameMsg.deselectEntity, () =>
      @deselectEntity()
    dispatcher.on gameMsg.clickPlaceMinion, () =>
      @deselectEntity()


  bindKeys: ->
    if ts.input?
      ts.input.bind(KEY.MOUSE1, "click")
      ts.input.bind(KEY.MOUSE2, "rightclick")

      ts.input.bind(KEY.Q, "buildTower1")
      ts.input.bind(KEY.W, "buildTower2")
      ts.input.bind(KEY.E, "buildTower3")
      ts.input.bind(KEY.R, "buildTower4")

      ts.input.bind(KEY.A, "sendMinion1")
      ts.input.bind(KEY.S, "sendMinion2")
      ts.input.bind(KEY.D, "sendMinion3")
      ts.input.bind(KEY.Z, "sendMinion4")
      ts.input.bind(KEY.X, "sendMinion5")
      ts.input.bind(KEY.C, "sendMinion6")

  isTouchDevice: =>
    ua = navigator.userAgent.toLowerCase()
    return ua.indexOf("Android") > -1 || ua.indexOf("iPhone") > -1 || ua.indexOf("iPad") > -1

  #Render the ui for building a tower
  update: ->
    if @pickedTower?
      mousePos = @getMousePos()
      if @isTouchDevice()
        if @lastTouch?
          @lastTouch = {x: mousePos.x, y: mousePos.y}
          @showTowerOverlay mousePos.x, mousePos.y, @pickedTower.towerType
      else
        @showTowerOverlay mousePos.x, mousePos.y, @pickedTower.towerType
    else
      @hideTowerOverlay();
    if @pickedMinion? && !@isTouchDevice()
      mousePos = @getMousePos()
      @showMinionOverlay mousePos.x, mousePos.y, @pickedMinion.minionType
    else
      @hideMinionOverlay()
    if ts.input? && ts.input.pressed('click')
      @handleClickDown()
    if ts.input? && ts.input.released('click')
      @handleClickUp()
    @checkKeys();
    @checkHover();

  setFogOfWarOpacity: (opacity) ->
    @fogOfWarOpacity = opacity

  checkKeys: ->
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if ts.input? && player?
        playerTowers = player.getTowers()
        for tower, num in playerTowers
          if ts.input.pressed("buildTower"+(num+1)) # +1 because of basic tower
            @pickTower(tower.towerType)
        for minionNum in [1..6]
          if ts.input.pressed("sendMinion"+minionNum)
            @pickMinionNum(minionNum)

  # Check if we are hovering over a clickable entity
  checkHover: ->
    if ts.ua.touch || !@document?
      return false
    @document.body.style.cursor = null
    if @pickedTower?
      return false
    mousePos = @getMousePos()
    towersInArea = ts.game.towerManager.getTowersInArea(mousePos.x, mousePos.y, 48)
    for tower in towersInArea
      tower.handleHover(mousePos.x, mousePos.y)
    castlesInArea = ts.game.castleManager.getCastlesInArea(mousePos.x, mousePos.y, 64)
    for castle in castlesInArea
      castle.handleHover(mousePos.x, mousePos.y)
    return true

  getMousePos: ->
    mousePos = ts.system.stage.getMousePosition();
    if @isTouchDevice()
      mousePos = {
        x: ts.input.mouse.x / ts.ua.pixelRatio
        y: ts.input.mouse.y / ts.ua.pixelRatio
      }
    mousePos = {
      x: (mousePos.x - ts.system.container.x) / ts.system.container.scale.x,
      y: (mousePos.y - ts.system.container.y) / ts.system.container.scale.y
    };
    return mousePos


  draw: ->
    if @isTouchDevice() && @lastTouch? && @pickedTower?
      @drawMobileHelpers(@lastTouch.x, @lastTouch.y)
    @drawMessages()
    @drawHighlights()
    if ts.game.debugMode
      @drawDebugHelpers()

  renderTowerButtons: ->

  renderMinionButtons: ->

  ###
  Draws the information pane showing tower details, minion details etc
  ###
  drawInfoPanel: (xPos, yPos, headline, text) ->

  ###
    Draws stuff like 'your minion has leveled up', 'you've destroyed an opponents castle' etc
  ###
  drawMessages: () ->
    if @messageBuffer.length == 0
      return false
    for message, idx in @messageBuffer by -1
      timePassed = ts.getCurrentConstantTime() - message.startTime
      if message.totalTime != 0 && timePassed > message.totalTime
        @messageBuffer.splice(idx, 1)
      else
        @drawText(message.text)

  drawText: (text, xPos, yPos, alignment) ->
    if typeof PIXI == "undefined"
      return false
    xPos = xPos ||  ts.game.getCanvasDimensions().width / 2
    yPos = yPos || 20
    alignment = alignment || "center"
    textObject = new PIXI.Text(text, {align: alignment, fill: 'white'})
    textObject.position.x = xPos
    textObject.position.y = yPos
    textObject.zIndex = config.text.zIndex
    ts.system.container.addChild(textObject)
    return textObject

  drawHighlights: ->
    tileSize = config.tileSize
    if @highlightedPosition?
      @drawDarkness()
      xStart = @highlightedPosition.x * tileSize;
      yStart = @highlightedPosition.y * tileSize;
      totalOpacityChange = 100
      opacity = (Math.floor(((Date.now() - @highlightedPosition.startTime) / config.highlightFlashRate / totalOpacityChange * 1000)) % totalOpacityChange) / totalOpacityChange
      if opacity > 0.5
        opacity = 1 - opacity
      opacity += 0.2
      graphics = ts.game.graphics
      graphics.beginFill(0xFFFFFF, opacity)
      graphics.drawRect(xStart, yStart, tileSize, tileSize)
      graphics.endFill()
    if @highlightedArea?
      xStart = @highlightedArea.x * tileSize;
      yStart = @highlightedArea.y * tileSize;
      width = @highlightedArea.width * tileSize;
      height = @highlightedArea.height * tileSize;
      totalOpacityChange = 100
      opacity = (Math.floor(((Date.now() - @highlightedArea .startTime) / config.highlightFlashRate / totalOpacityChange * 1000)) % totalOpacityChange) / totalOpacityChange
      if opacity > 0.5
        opacity = 1 - opacity
      opacity += 0.2
      graphics = ts.game.graphics
      graphics.beginFill(0xFFFFFF, opacity)
      graphics.drawRect(xStart, yStart, width, height)
      graphics.endFill()
    return true

  #Draws transparent black over the entire canvas, used for tutorial.
  drawDarkness: () ->
    tileSize = config.tileSize
    map = _.clone(ts.game.map);
    graphics = ts.game.graphics
    width = map.width * tileSize
    height = map.height * tileSize
    graphics.beginFill(0x000000, 0.3)
    graphics.drawRect(0, 0, width, height)
    graphics.endFill()


  drawMobileHelpers: (xPos, yPos) ->
    xStart = Math.floor(xPos / config.tileSize) * config.tileSize
    yStart = Math.floor(yPos / config.tileSize) * config.tileSize
    tileSize = config.tileSize
    graphics = ts.game.graphics
    graphics.beginFill(0xFFFFFF, 0.4)
    graphics.drawRect(xStart, 0, tileSize, config.gameWidth)
    graphics.endFill()
    graphics.beginFill(0xFFFFFF, 0.4)
    graphics.drawRect(0, yStart, config.gameWidth, tileSize)
    graphics.endFill()

  drawGrid: () ->
    graphics = ts.game.graphics
    if !ts.game.map
      return false
    map = _.clone(ts.game.map)
    tileSize = 48 * ts.system.scale
    for x in [0..map.width]
      for y in [0..map.height]
        if x % 2 == y % 2
          graphics.beginFill(0x000000, 0.2)
          graphics.drawRect(x * tileSize, y * tileSize, tileSize, tileSize)
          graphics.endFill()

  getFogOfWarDimensions: (opposingTeam) ->
    if !ts.game.map?.buildRestrictions?
      return null;
    map = _.clone(ts.game.map);
    br = map.buildRestrictions[opposingTeam]
    if br?.x?.min?
      xPos = br.x.min
      width = Math.min(br.x.max, map.width) - xPos + 1
    else
      xPos = 0
      width = map.width
    if br?.y?.min?
      yPos = br.y.min
      height = Math.min(br.y.max, map.height) - yPos + 1
    else
      yPos = 0
      height = map.height
    return {
      x: xPos
      y: yPos
      width: width
      height: height
    }

  createFogOfWar: () ->
    @fogOfWar = new PIXI.Graphics();
    @fogOfWar.zIndex = 50
    playerTeam = 0
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      playerTeam = player.getTeam();
    opposingTeam = if playerTeam == 0 then 1 else 0
    dimensions = @getFogOfWarDimensions(opposingTeam);
    for key, item of dimensions
      dimensions[key] = item * config.tileSize;
    @fogOfWar.beginFill(0x000000, @fogOfWarOpacity)
    @fogOfWar.drawRect(dimensions.x + ts.game.paddingLeft, dimensions.y + ts.game.paddingTop, dimensions.width, dimensions.height)
    @fogOfWar.endFill()

  enableFogOfWar: () ->
    if !@fogOfWar
      @createFogOfWar()
      ts.system.container.addChild(@fogOfWar)

  disableFogOfWar: () ->
    if @fogOfWar
      ts.system.container.removeChild(@fogOfWar)
      delete @fogOfWar

  drawVisionCircle: (ctx, x, y, radius) ->
    ctx.beginPath();
    ctx.arc(x, y, radius, 0, 2 * Math.PI, false);
    ctx.fillStyle = 'black';
    ctx.fill();

  drawDebugHelpers: ->
    if !@debugCanvas?
      @debugCanvas = document.createElement('canvas')
    @debugCanvas.width = 1000
    @debugCanvas.height = 1000
    graphics = ts.game.graphics
    for helper, idx in @debugHelpers by -1
      if Date.now() - helper.startTime > (helper.time * 1000)
        @debugHelpers.splice(idx, 1)
      else
        if helper.c == 'red'
          graphics.beginFill(0xFF0000, 0.2)
        else if helper.c == 'green'
          graphics.beginFill(0x00FF00, 0.2)
        else if helper.c == 'blue'
          graphics.beginFill(0x0000FF, 0.2)
        if helper.type == "square"
          graphics.drawRect(helper.x, helper.y, helper.w, helper.h);
        if helper.type == "circle"
          graphics.drawCircle(helper.x, helper.y, helper.r)
        graphics.endFill()

  handleClickDown: ->
    mousePos = @getMousePos()
    @lastClick = {x: mousePos.x, y: mousePos.y}
    if @pickedTower?
      @lastTouch = {x: mousePos.x, y: mousePos.y}
      @clickWithPickedTower(mousePos.x, mousePos.y)
    else if @pickedMinion?
      @lastTouch = {x: mousePos.x, y: mousePos.y}
      @clickWithPickedMinion(mousePos.x, mousePos.y)
    else
      if @selectedEntity?
        @clickWithSelectedEntity(mousePos.x, mousePos.y)
      if !@selectedEntity? #Could be deselected by above if statement so separate if here.
        ts.game.dispatcher.emit gameMsg.clickNoSelection, mousePos.x, mousePos.y

  handleClickUp: ->
    mousePos = @getMousePos()
    if @pickedTower?
      @touchWithPickedTower(mousePos.x, mousePos.y)

  pickTower: (towerType) ->
    @deselectEntity()
    if towerType == false
      @pickedTower = null;
      @lastTouch = null;
    else if towerConfig[towerType]?
      player = ts.game.playerManager.getMainPlayer()
      if player.canPickTower(towerType)
        @pickedTower = towerConfig[towerType]
    ts.game.dispatcher.emit gameMsg.pickedTower, towerType  #This is to notify the front end of the game changing pickedTower (when it's deselected etc)

  pickMinionNum: (minionNum) ->
    minions = minionConfig
    player = ts.game.playerManager.getMainPlayer()
    teamRaces = player.getTeamRaces()
    count = 1
    for type, minion of minions
      if minion.race in teamRaces
        if count == minionNum
          return @pickMinion(type)
        else
          count++
    return false

  pickMinion: (minionType) ->
    @deselectEntity()
    if minionType == false
      @pickedMinion = null;
      @lastTouch = null;
    else if minionConfig[minionType]?
      ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
        if player.canPickMinion(minionType)
          @pickedMinion = minionConfig[minionType]
    ts.game.dispatcher.emit gameMsg.pickedMinion, minionType

  touchWithPickedTower: (clickX, clickY) ->
    if @isTouchDevice()
      if @lastTouch?
        @placeTower(@lastTouch.x, @lastTouch.y, @pickedTower.towerType)
        @pickTower(false)

  clickWithPickedTower: (clickX, clickY) ->
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if !@isTouchDevice() && player.getGold() >= @pickedTower.cost
        @placeTower(clickX, clickY, @pickedTower.towerType)
        @pickTower(false)

  clickWithPickedMinion: (clickX, clickY) ->
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      @placeMinion(clickX, clickY, minionConfig[@pickedMinion.minionType])



  clickWithSelectedEntity: (clickX, clickY) ->
    @deselectEntity()

  entityHover: (entity) ->
    document.body.style.cursor = 'pointer'

  entityClicked: (entity) ->
    if !@selectedEntity?
      @selectEntity(entity)
    else if ts.game.functions.getDist(@lastClick, entity.getCenter()) < ts.game.functions.getDist(@lastClick, @selectedEntity.getCenter())
      @deselectEntity()
      @selectEntity(entity)

  selectEntity: (entity) ->
    if @selectedEntity?
      @deselectEntity()
    @selectedEntity = entity
    if @selectedEntity.ctype == GameEntity.CTYPE.TOWER
      @showTowerInfo(@selectedEntity)
    if @selectedEntity.ctype == GameEntity.CTYPE.CASTLE
      @showCastleInfo(@selectedEntity)
    @selectedEntity.select();

  deselectEntity: ->
    if @selectedEntity?
      if @selectedEntity.ctype == GameEntity.CTYPE.TOWER
        @hideTowerPanel()
      if @selectedEntity.ctype == GameEntity.CTYPE.CASTLE
        @hideInfoPanel()
      @selectedEntity.deselect()
      @selectedEntity = null

  ###
   * Shows a transparent tower overlay with radius when you move your mouse around
   *
  ###
  showTowerOverlay: (xPos, yPos, type) ->
    if !type?
      return @hideTowerOverlay()
    towerPos = @getPosFromMouseCoordinates(xPos, yPos)
    if @towerOverlay?.towerType? && @towerOverlay.towerType == type
      xPos = towerPos.xCoord * config.tileSize
      yPos = towerPos.yCoord * config.tileSize
      @towerOverlay.pos = {x: xPos, y: yPos}
      @towerOverlay.last = {x: xPos, y: yPos}
    else
      @hideTowerOverlay();
      towerSettings = towerConfig[type]
      settings =
        towerType: type
        range: towerSettings.range
        auraRange: towerSettings.auraRange
        cost: towerSettings.cost
        imageName: if towerSettings.imageName? then towerSettings.imageName else null
        buildsOnRoads: if towerSettings.buildsOnRoads? then towerSettings.buildsOnRoads else false
      @towerOverlay = ts.game.spawnEntity GameEntity.CTYPE.TOWEROVERLAY, towerPos.xPos, towerPos.yPos, settings

  hideTowerOverlay: ->
    if @towerOverlay?
      @towerOverlay.instantKill()
      @towerOverlay = null

  ###
   * Shows a transparent tower overlay with radius when you move your mouse around
   *
  ###
  showMinionOverlay: (xPos, yPos, type) ->
    if !type?
      return @hideMinionOverlay()
    minionPos = @getPosFromMouseCoordinates(xPos, yPos)
    if @minionOverlay?.minionType? && @minionOverlay.minionType == type
      xPos = minionPos.xCoord * config.tileSize
      yPos = minionPos.yCoord * config.tileSize
      @minionOverlay.pos = {x: xPos, y: yPos}
      @minionOverlay.last = {x: xPos, y: yPos}
    else
      @hideMinionOverlay();
      player = ts.game.playerManager.getMainPlayer()
      minionSettings = minionConfig[type]
      settings =
        width: minionSettings.width
        height: minionSettings.height
        minionType: type
        cost: player.getMinionCost(type)
        souls: player.getMinionSoulCost(type)
        imageName: if minionSettings.imageName? then minionSettings.imageName else null
        frames: minionSettings.frames
      @minionOverlay = ts.game.spawnEntity GameEntity.CTYPE.MINIONOVERLAY, minionPos.xPos, minionPos.yPos, settings

  hideMinionOverlay: ->
    if @minionOverlay?
      @minionOverlay.instantKill()
      @minionOverlay = null

  getPosFromMouseCoordinates: (xPos, yPos) ->
      tileSize = config.tileSize;
      #Find the tile that is closest to where we want to place it.
      xCoord = Math.floor(xPos / tileSize);
      yCoord = Math.floor(yPos / tileSize);
      {
        xCoord
        yCoord
      }

  ###
   * This is called when a player clicks to place a tower. It tells the dispatcher to
   * send a build tower command which informs the server.
  ###
  placeTower: (xPos, yPos, towerType) ->
    settings = towerConfig[towerType]
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      towerPos = @getPosFromMouseCoordinates(xPos, yPos)
      takenLevel = 0
      if settings.buildsOnRoads == true
        takenLevel = 1
      isPositionTaken = ts.game.towerManager.isPositionTaken(towerPos.xCoord, towerPos.yCoord, player.getTeam(), takenLevel)
      if isPositionTaken
        return false
      ts.game.dispatcher.emit(gameMsg.clickPlaceTower, towerPos.xCoord, towerPos.yCoord, towerType)

  ###
   * This is called when a player clicks to place a minion. It tells the dispatcher to
   * send a build minion command which informs the server.
  ###
  placeMinion: (xPos, yPos, settings) ->
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      minionPos = @getPosFromMouseCoordinates(xPos, yPos)
      isValidSpawnPoint = ts.game.minionManager.isValidSpawnPoint(minionPos.xCoord, minionPos.yCoord, player.getTeam())
      if !isValidSpawnPoint
        if !@isTouchDevice()
          @pickMinion(false)
        return false
      if !player.canSendMinion(@pickedMinion.minionType)
        return false
      ts.game.dispatcher.emit(gameMsg.clickPlaceMinion, minionPos.xCoord, minionPos.yCoord, settings.minionType)

  upgradeSelectedTower: () ->
    ctypes = GameEntity.CTYPE
    if !@selectedEntity || @selectedEntity.ctype != ctypes.TOWER
      return false
    ts.game.dispatcher.emit gameMsg.clickUpgradeTower, @selectedEntity

  upgradedTower: (tower) ->
    if tower == @selectedEntity
      @showTowerInfo(tower)

  sellSelectedTower: () ->
    ctypes = GameEntity.CTYPE
    if !@selectedEntity || @selectedEntity.ctype != ctypes.TOWER
      return false
    ts.game.dispatcher.emit gameMsg.clickSellTower, @selectedEntity
    @deselectEntity()

  addMessage: (text, time) ->
    @messageBuffer.push({text: text, totalTime: time, startTime: ts.getCurrentConstantTime()})

  removeMessage: (text) ->
    for message, idx in @messageBuffer
      if message.text == text
        @messageBuffer.splice(idx, 1)
        return true

  showTowerInfo: (tower) ->
    stats = tower.getStats()
    level = tower.level
    upgradeCost = 0; sellValue = 0;
    modifiers = tower.getModifierDetails()
    auras = tower.getAuraDetails()
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player.getId() == tower.owner.getId()
        upgradeCost = tower.getNextLevelCost()
        sellValue = tower.getSellValue()
    @showTowerPanel(tower.name, tower.owner.getTeam(), level, stats, modifiers, auras, upgradeCost, sellValue);

  showTowerPanel: (title, team, level, stats, modifiers, auras, upgradeCost, sellValue) ->
    ts.game.dispatcher.emit gameMsg.showTowerPanel, title, team, level, stats, modifiers, auras, upgradeCost, sellValue

  hideTowerPanel: ->
    ts.game.dispatcher.emit gameMsg.hideTowerPanel

  showCastleInfo: (castle) ->
    boosts = castle.boosts
    title = "Castle"
    player = ts.game.playerManager.getMainPlayer()
    opponents = ""
    if player.getTeam() == castle.team
      opponents = "opponents "
    text = "When this castle is destroyed all minions on your " + opponents + "team gain:<br><ul>"
    for name, amount of boosts
      text += "<li>+" + parseInt(amount * 100) + "% " + name.charAt(0).toUpperCase() + name.slice(1) + "</li>"
    text += "</ul>"
    options = {team: castle.team}
    @showInfoPanel(title, text, null, options)

  showInfoPanel: (title, text, buttons, options) ->
    ts.game.dispatcher.emit gameMsg.showInfoPanel, title, text, buttons, options

  hideInfoPanel: ->
    ts.game.dispatcher.emit gameMsg.hideInfoPanel

  showHelperText: (text) ->
    ts.game.dispatcher.emit gameMsg.showHelperText, text

  hideHelperText: () ->
    ts.game.dispatcher.emit gameMsg.hideHelperText

  highlightPosition: (details) ->
    @highlightedPosition = details
    if @highlightedPosition?
      @highlightedPosition.startTime = Date.now()

  highlightArea: (details) ->
    @highlightedArea = details
    if @highlightedArea?
      @highlightedArea.startTime = Date.now()

  addDebugSquare: (x, y, w, h, color = 'red', time = 0.5) ->
    if !ts.game.debugMode
      return false
    square = {type: 'square', x, y, w, h, c: color, time, startTime: Date.now()}
    @debugHelpers.push(square)

  addDebugCircle: (center, radius, color = 'red', time = 0.5) ->
    if !ts.game.debugMode
      return false
    circle = {type: 'circle', x: center.x, y: center.y, c: color, r: radius, time, startTime: Date.now()}
    @debugHelpers.push(circle)

module.exports = Hud
