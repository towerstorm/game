Bullet = require("../game/entities/bullet.coffee")
Castle = require("../game/entities/castle.coffee")
Doodad = require("../game/entities/doodad.coffee")
GameEntity = require("../game/entities/game-entity.coffee")
Gem = require("../game/entities/gem.coffee")
Minion = require("../game/entities/minion.coffee")
MinionOverlay = require("../game/entities/minion-overlay.coffee")
SpawnPoint = require("../game/entities/spawn-point.coffee")
TempMinion = require("../game/entities/temp-minion.coffee")
TempTower = require("../game/entities/temp-tower.coffee")
Tower = require("../game/entities/tower.coffee")
TowerOverlay = require("../game/entities/tower-overlay.coffee")
VFX = require("../game/entities/vfx.coffee")
Entity = require("./entity.coffee")
System = require("./system.coffee")
Timer = require("./timer.coffee")

config = require("config/general")

class Game
  constructor: ->
    @reset()
    i = ts.system.stage.children.length - 1
    while i >= 0
      ts.system.stage.children[i].mask = null
      i--
    ts.system.stage.setBackgroundColor @clearColor.replace('#', '0x')
    ts.system.stage.setInteractive if @interactive then true else false
    if @interactive
      ts.system.stage.mousemove = ts.system.stage.touchmove = @mousemove.bind(this)
      ts.system.stage.click = ts.system.stage.tap = @click.bind(this)
      ts.system.stage.mousedown = ts.system.stage.touchstart = @mousedown.bind(this)
      ts.system.stage.mouseup = ts.system.stage.mouseupoutside = ts.system.stage.touchend = ts.system.stage.touchendoutside = @mouseup.bind(this)
    if ts.ua.mobile or System.canvas
      # clearColor fix
      bg = new (PIXI.Graphics)
      bg.beginFill @clearColor.replace('#', '0x')
      bg.moveTo 0, 0
      bg.lineTo ts.system.width, 0
      bg.lineTo ts.system.width, ts.system.height
      bg.lineTo 0, ts.system.height
      bg.endFill()
      ts.system.stage.addChild bg
    return

  reset: ->
    @clearColor = 'rgba(0,0,0,1)'
    @cTypeToClassMap = {}
    @sortBy = null
    @interactive = true
    @entLastTick = 0
    i = 0
    if @entities?
      while i < @entities.length
        typeEntities = @entities[i]
        j = 0
        while j < typeEntities.length
          @removeEntity typeEntities[j]
          j++
        i++
    @removeEntities()
    @entities = @getEmptyEntitiesArray()
    @entityPool = @getEmptyEntitiesArray()
    @_killedEnts = []
    @_deferredRemove = []
    @_levelToLoad = null
    @entLastTick = 0
    @removeLastTick = 0
    @logicPaused = false
    #For pausing the game while waiting for the next tick from the network.
    @totalLogicPauses = 0
    return

  click: (event) ->
  mousedown: (event) ->
  mouseup: (event) ->
  mousemove: (event) ->

  loadLevel: (data) ->
    @entities = @getEmptyEntitiesArray()
    @entityPool = @getEmptyEntitiesArray()
    @initCTypeToClassMap()

  getEmptyEntitiesArray: ->
    ents = []
    key = null
    val = 0
    for key of GameEntity.CTYPE
      if GameEntity.CTYPE.hasOwnProperty(key)
        val = GameEntity.CTYPE[key]
        ents[val] = []
    return ents

  getEntitiesByType: (type) ->
    if !type?
      allEntities = []
      allEntities.concat.apply allEntities, @entities
      return allEntities
    @entities[type]

  initCTypeToClassMap: ->
    @cTypeToClassMap = {}
    @cTypeToClassMap[GameEntity.CTYPE.GAMEENTITY] = GameEntity
    @cTypeToClassMap[GameEntity.CTYPE.DOODAD] = Doodad
    @cTypeToClassMap[GameEntity.CTYPE.CASTLE] = Castle
    @cTypeToClassMap[GameEntity.CTYPE.TOWER] = Tower
    @cTypeToClassMap[GameEntity.CTYPE.MINION] = Minion
    @cTypeToClassMap[GameEntity.CTYPE.BULLET] = Bullet
    @cTypeToClassMap[GameEntity.CTYPE.MINIONOVERLAY] = MinionOverlay
    @cTypeToClassMap[GameEntity.CTYPE.TOWEROVERLAY] = TowerOverlay
    @cTypeToClassMap[GameEntity.CTYPE.TEMPMINION] = TempMinion
    @cTypeToClassMap[GameEntity.CTYPE.TEMPTOWER] = TempTower
    @cTypeToClassMap[GameEntity.CTYPE.GEM] = Gem
    @cTypeToClassMap[GameEntity.CTYPE.VFX] = VFX
    @cTypeToClassMap[GameEntity.CTYPE.SPAWNPOINT] = SpawnPoint
    return

  spawnEntity: (cType, x, y, settings) ->
    ent = @getEntityFromPool(cType, x, y, settings)
    @addEntity ent
    ent

  addEntity: (ent) ->
    @entities[ent.ctype].push ent
    return

  arePropertiesReset: (item, visitedItems, itemPath) ->
    visitedItems = visitedItems or []
    itemPath = itemPath or [ 'root' ]
    visitedItems.push item
    for prop of item
      if item.hasOwnProperty(prop)
        if [
            '_killed'
            '_destroyed'
            'ctype'
            'visible'
            'alpha'
            'poolCount'
            'inPool'
          ].indexOf(prop) == -1
          if typeof item[prop] == 'object' and visitedItems.indexOf(item[prop]) == -1
            itemPath.push prop
            @arePropertiesReset(item[prop], visitedItems, itemPath)
            itemPath.pop()
          else if typeof item[prop] != 'function'
            if item[prop] and !ts.isServer
              throw new Error('Property ' + prop + ', of path: ' + itemPath.join(' -> ') + ', has a value of: ' + item[prop] + ' after reset. VisitedItems: ' + visitedItems.join(','))
    return

  getEntityFromPool: (cType, x, y, settings) ->
    ent = null
    if @entityPool[cType].length > 0
      ent = @entityPool[cType].pop()
      if config.debug
        @arePropertiesReset ent
      ent.inPool = false
      ent.constructor(x, y, settings or {})
      return ent
    @createNewEntity(cType, x, y, settings)

  createNewEntity: (cType, x, y, settings) ->
    entityClass = @cTypeToClassMap[cType]
    ent = new entityClass(x, y, settings or {})
    ent

  addEntityToPool: (ent) ->
    if ent.inPool
      return false
    ent.reset()
    ent.poolCount++
    ent.inPool = true
    if config.debug
      @arePropertiesReset ent
    @entityPool[ent.ctype].push ent
    return

  pauseLogic: ->
    ts.system.clock.pause()
    if !@logicPaused
      @totalLogicPauses++
    @logicPaused = true
    return

  unpauseLogic: ->
    ts.system.clock.unpause()
    @logicPaused = false
    return

  getEstimatedMaxLag: ->
    @totalLogicPauses * Timer.constantStep + config.timeBeforeFastForward

  run: (disableDraw) ->
    @update()
    if typeof document != 'undefined' and !disableDraw
      @draw()
    @doneTick()
    if @logicPaused
      return false
      #Stop any system loops by returning false.
    true

  update: ->
    #Add all entities killed in the last update to the remove list
    if !@logicPaused and ts.getCurrentTick() > @entLastTick and ts.system.running
      #Don't logic loop more than once per tick.
      @entLastTick = ts.getCurrentTick()
      @removeEntities()
      @updateEntities()
      @sortEntities()
      @markEntitiesForRemoval()
    return

  killEntity: (ent) ->
    @_killedEnts.push ent
    return

  markEntitiesForRemoval: ->
    if !@logicPaused and @entLastTick > @removeLastTick
      #Don't logic loop more than once per tick.
      @removeLastTick = @entLastTick
      i = 0
      while i < @_killedEnts.length
        ent = @_killedEnts[i]
        @removeEntity ent
        i++
      @_killedEnts = []
    return

  removeEntity: (ent) ->
    # Remove this entity from the named entities
    # We can not remove the entity from the entities[] array in the midst
    # of an update cycle, so remember all killed entities and remove
    # them later.
    # Also make sure this entity doesn't collide anymore and won't get
    # updated or checked
    @_deferredRemove.push ent
    return

  removeEntities: ->
    # remove all killed entities
    if !@_deferredRemove?
      return

    i = 0
    while i < @_deferredRemove.length
      toKill = @_deferredRemove[i]
      if !@entities[toKill.ctype]?
        # console.log("Entity type: ", this._deferredRemove.ctype, " not found, full deferred Kill is: ", this._deferredRemove);
        # throw "ERROR: type "+this._deferredRemove.ctype+" not found in entities";
      else
        #                  console.log("Doing final remove on entity " + toKill.id);
        @entities[toKill.ctype].erase toKill
        toKill.destroy()
        @addEntityToPool toKill
      i++
    @_deferredRemove = []
    return

  updateEntities: ->
    currentTick = ts.getCurrentTick();
    i = 0
    while i < @entities.length
      typeEntities = @entities[i]
      j = 0
      while j < typeEntities.length
        ent = typeEntities[j]
        if !ent._killed
          ent.update(currentTick)
        j++
      i++
    return

  draw: ->
    if ts.game.largeTickQueue or ts.game.isFastForwarding
      return false
    @drawEntities()
    ts.system.renderer.render ts.system.stage
    return

  drawEntities: ->
    i = 0
    while i < @entities.length
      typeEntities = @entities[i]
      startTime = Date.now()
      j = 0
      while j < typeEntities.length
        typeEntities[j].draw()
        j++
      i++
    return

  sortEntities: ->
    if ts.system.container?
      ts.system.container.children.sort Game.SORT.Z_INDEX_POS_Y
    return

  doneTick: ->

  checkEntityPool: ->
    for ctype of @entityPool
      entities = @entityPool[ctype]
      i = 0
      while i < entities.length
        entity = entities[i]
        if entity and !ts.isServer
          if entity.inPool == false
            throw new Error('Entity in pool has inPool set to false')
          if @arePropertiesReset(entity)
            throw new Error('Entity in pool does not have its properties reset.')
        i++
    return

  @SORT:
    Z_INDEX_POS_Y: (a, b) ->
      if a.zIndex != b.zIndex
        #Highest priority is z-index
        return a.zIndex - (b.zIndex)
      if a.position.y + a.height != b.position.y + b.height
        #Next highest priority is how low down they are
        return a.position.y + a.height - (b.position.y + b.height)
      a.spawnTime - (b.spawnTime)
      #If they are exactly the same z-Index and pos just return whatever id is first so they don't flicker

module.exports = Game
