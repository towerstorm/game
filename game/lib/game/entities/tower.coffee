#global ts
Timer = require("../../engine/timer.coffee")
GameEntity = require("./game-entity.coffee")
AURAS = require("../auras/auras.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")
bulletConfig = require("config/bullets")
towerConfig = require("config/towers")

_ = require("lodash")

class Tower extends GameEntity
  ctype: GameEntity.CTYPE.TOWER
  name: "tower"

  constructor: (x, y, settings) ->
    @reset()
    @width = config.towers.width
    @height = config.towers.height
    @size = {x: @width, y: @height}
    @towerType = settings.id;
    super x, y, settings
    @loadLevelZero()
    @loadAnimations()
    @baseDamage = parseInt(@damage);
    @baseAttackSpeed = parseFloat(@attackSpeed);
    @baseRange = parseFloat(@range);
    @auraRangeScaled = @auraRange * config.tileSize
    @auraRangeScaledSquared = @auraRangeScaled * @auraRangeScaled
    @canBeSelected = true
    @calculateReloadTicks();
    @calculateDamage();
    @calculateRange();
    @runAuras();
    @checkForNearbyAuras();
    @loadTowerModifiers();
    @spawnAllVFX()
    if @animSheet
      @animSheet.setTint(config.tint.default)

  reset: ->
    super();
    @race = null
    @towerType = null
    @speed = 0
    @canBeSelected = false
    @buildsOnRoads = false
    @imageNum = null
    @imageName = null
    @idleFrames = null
    @idleFrameTime = null
    @attackFrames = null
    @attackFrameTime = null
    @attackLoopFrames = null
    @attackAngles = null
    @totalFramesPerAttack = null
    @totalRotationFrames = null
    @bulletSpawnOffsets = null
    @baseDamage = 0
    @damage = 0
    @damageBoost = 0
    @dpsBoost = 0
    @damage = 0
    @damageMethod = null
    @baseAttackSpeed = 0
    @attackSpeed = 0
    @attackSpeedBoost = 0
    @reloadTicks = 0
    @lastShot = null
    @shotTimes = []
    @targetMinions = []
    @maxTargets = 0
    @baseRange = 0
    @range = 0
    @rangeBoost = 0
    @rangeScaled = 0
    @rangeScaledSquared = 0
    @auraRange = 0
    @auraRangeScaled = 0
    @auraRangeScaledSquared = 0
    @bonusGold = 0
    @level = 0
    @hasBeenSeen = false
    @mods = {}
    @modifiers = []
    @auras = {}
    @buffs = []
    @angle = 0;
    @lastBullet = null
    @singleBullet = false
    @shootVFX = null
    @shootVFXEntity = null
    @currentBullets = []
    @stopAttackingWhenBulletsAreDead = null
    @selectTime = null
    @isUpgrading = false

  loadLevelZero: ->
    @maxTargets = 1
    levelSettings = @getLevelSettings(0)
    for own name, setting of levelSettings
      if typeof(setting) == "object"
        @[name] = _.extend(@[name], setting)
      else
        @[name] = setting

  loadAnimations: ->
    @zIndex = @zIndex || config.towers.zIndex
    @animSheet =  ts.game.cache.getAnimationSheet('towers/' + @imageName, config.towers.width, config.towers.height, @zIndex)
    @size = {x: config.towers.width, y: config.towers.height}
    @offset = {x: 8, y: 16}
    @idleFrameTime = @idleFrameTime || 0.05
    @attackFrameTime = @attackFrameTime || 0.05
    @loadIdleAnimations(@idleFrames, @totalRotationFrames, @totalFramesPerAttack, @attackAngles)
    @loadAttackAnimations(@totalRotationFrames, @totalFramesPerAttack, @attackFrames, @attackAngles)
    @loadAttackLoopAnimations(@attackLoopFrames)

  getTotalFrames: (totalRotationFrames, totalFramesPerAttack, attackAngles) ->
    totalFramesPerAttack = totalFramesPerAttack || 0;
    totalAttackAngles = if attackAngles? then attackAngles.length else totalRotationFrames
    totalFrames = totalRotationFrames + (totalFramesPerAttack * totalAttackAngles)
    return totalFrames

  getIdleFrameNums: (totalRotationFrames, totalFramesPerAttack, attackAngles) ->
    totalFrames = @getTotalFrames(totalRotationFrames, totalFramesPerAttack, attackAngles)
    currentAngle = 0
    angleIncrement = 360 / totalRotationFrames
    idleFrames = []
    nextIdleFrame = null
    for x in [0...totalFrames]
      if !nextIdleFrame? || nextIdleFrame == x
        idleFrames.push(x)
        nextIdleFrame = null
        if totalFramesPerAttack?
          if attackAngles?
            if currentAngle in attackAngles
              nextIdleFrame = x + (totalFramesPerAttack + 1)
          else
            nextIdleFrame = x + (totalFramesPerAttack + 1)
        currentAngle += angleIncrement
    return idleFrames

  loadIdleAnimations: (idleFrames, totalRotationFrames, totalFramesPerAttack, attackAngles) ->
    idleAnimFrames = [0]
    if idleFrames?
      for x in [1...idleFrames]
        idleAnimFrames.push(x)
    @addAnim "idle", @idleFrameTime, idleAnimFrames
    idleFrameNums = @getIdleFrameNums(totalRotationFrames, totalFramesPerAttack, attackAngles)
    angleIncrement = 360 / totalRotationFrames
    currentAngle = 0
    for num in idleFrameNums
      @addAnim(currentAngle + "deg", @idleFrameTime, [num]);
      currentAngle += angleIncrement

  loadAttackAnimations: (totalRotationFrames, totalFramesPerAttack, attackFrames, attackAngles) ->
    totalFrames = @getTotalFrames(totalRotationFrames, totalFramesPerAttack, attackAngles)
    idleFrameNums = @getIdleFrameNums(totalRotationFrames, totalFramesPerAttack, attackAngles)
    skipFrames = 0
    currentAngle = 0
    angleIncrement = 360 / totalRotationFrames
    for x in [0...totalFrames]
      if skipFrames
        skipFrames--
      else
        if x not in idleFrameNums
          idleAnim = x - 1
          offsetAttackFrames = @getOffsetAttackFrames(attackFrames, idleAnim)
          @addAnim(currentAngle + "deg-attack", @attackFrameTime, offsetAttackFrames, true)
          if attackAngles?
            currentAngle = @getNextAngle(attackAngles, currentAngle)
          else
            currentAngle += angleIncrement
          skipFrames = totalFramesPerAttack
    if !totalRotationFrames?
      if totalFramesPerAttack?
        @addAnim("0deg-attack", @attackFrameTime, attackFrames, true)

  getOffsetAttackFrames: (attackFrames, offsetAmount) ->
    offsetAttackFrames = []
    for num in attackFrames #Offset the attack frames by the initial frame we start on
      offsetAttackFrames.push(num + offsetAmount)
    return offsetAttackFrames

  getNextAngle: (attackAngles, currentAngle) ->
    if currentAngle not in attackAngles
      return null
    return attackAngles[attackAngles.indexOf(currentAngle) + 1]

  loadAttackLoopAnimations: (attackLoopFrames) ->
    if attackLoopFrames
      @addAnim("attack-loop", @attackFrameTime, attackLoopFrames)

  calculateReloadTicks: () ->
    @reloadTicks = @getReloadTicks(@getAttackSpeed(@baseAttackSpeed, @attackSpeedBoost))

  getAttackSpeed: (attackSpeed, attackSpeedBoost) ->
    if attackSpeedBoost > 0
      percent = Math.min(config.towers.attackSpeedBoostCap, attackSpeedBoost)
      attackSpeed = attackSpeed * (1 + (percent / 100));
    attackSpeed = attackSpeed.round(3);
    return attackSpeed

  getReloadTicks: (attackSpeed) ->
    reloadTicks = ((1 / attackSpeed) / Timer.constantStep).round(8)
    return reloadTicks

  calculateDamage: ->
    @damage = @getDamage(@baseDamage, @damageBoost)

  getDamage: (baseDamage, damageBoost) ->
    if !baseDamage?
      return 0
    damage = baseDamage
    if damageBoost? && damageBoost > 0
      percent = Math.min(config.towers.damageBoostCap, damageBoost)
      damage = damage * (1 + (percent / 100));
    damage = Math.round(damage);
    return damage

  calculateRange: ->
    @range = @getRange(@baseRange, @rangeBoost)
    @rangeScaled = @range * config.tileSize
    @rangeScaledSquared = @rangeScaled * @rangeScaled

  getRange: (baseRange, rangeBoost) ->
    range = baseRange
    if rangeBoost? && rangeBoost > 0
      percent = Math.min(config.towers.rangeBoostCap, rangeBoost)
      range = range * (1 + (percent / 100));
    range = range.round(2);
    return range;

  ###
   * Runs all allied tower modifiers that this tower has on all it's nearby allied towers :D
  ###
  runAuras: ->
    if @auras?
      towers = @getTowersInAuraRange(true)
      for tower in towers
        tower.addBuffs(@auras, @)

  ###
   * When this tower is destroyed it needs to somehow clean up all modifiers
   * that is has applied to nearby allied towers
  ###
  killAuras: ->
    if @auras
      towers = @getTowersInAuraRange(true)
      for tower in towers
        tower.removeBuffs(@)

  ###
   * For towers that are spawned after a tower with mods, checks for nearby mods and injects them
   * into itself
   *
   * Don't use getTowersInAuraRange as we are checking the remote towers range, not our own.
  ###
  checkForNearbyAuras: ->
    allTowers = ts.game.getEntitiesByType(GameEntity.CTYPE.TOWER);
    for tower in allTowers
      if tower.auras? && tower.getOwner().getTeam() == @getOwner().getTeam()
        dist = ts.game.functions.getDistSqrd(@pos, tower.pos)
        if dist < tower.auraRangeScaledSquared #Check it's range, not our own
          @addBuffs tower.auras, tower

  loadTowerModifiers: ->
    @modifiers = []
    if @mods?.tower?
      for name, details of @mods.tower
        mod = ts.game.modPool.getModifier(name, details)
        mod.inject(@)
        @modifiers.push(mod)

  ###
    - Gets all towers in range of this tower, does not get itself
  ###
  getTowersInAuraRange: (alliedOnly) ->
    if !alliedOnly?
      alliedOnly = false
    towers = []
    allTowers = ts.game.getEntitiesByType(GameEntity.CTYPE.TOWER);
    for tower in allTowers
      if alliedOnly == false || @getOwner().getTeam() == tower.getOwner().getTeam()
        dist = ts.game.functions.getDistSqrd(@pos, tower.pos)
        if dist != 0 && dist < @auraRangeScaledSquared #Squared distance check is faster
          towers.push tower
    return towers

  canAttackMinion: (minion) ->
    if minion.moveType not in @attackMoveTypes
      return false
    return true

  checkTargetIsValid: (minion) ->
    if !minion?
      return false;
    if !minion.visible
      return false
    if !minion.canBeShot()
      return false
    if !@canAttackMinion(minion)
      return false
    if @attackAngles? && @getAngleToMinion(minion) not in @attackAngles
      return false
    if @getOwner()?
      if @getOwner().getTeam() == minion.team && !ts.game.canAttackOwnMinions()
        return false
    dist = ts.game.functions.getDistSqrd(@getCenter(), minion.getCenter())
    if dist > @rangeScaledSquared #Squared distance check is faster
      return false
    return true

  scanForTargets: ->
    if @targetMinions.length
      for minion, idx in @targetMinions by -1
        if !@checkTargetIsValid(minion)
          @targetMinions.splice(idx, 1)
    if !@targetMinions.length || @targetMinions.length < @maxTargets #seperate if in case target minions become invalid above
      towerCenter = @getCenter()
      minions = ts.game.minionManager.getMinionsInArea(towerCenter.x, towerCenter.y, @range, true)
      for minion in minions
        if @targetMinions.length < @maxTargets && minion not in @targetMinions && @checkTargetIsValid(minion)
          @targetMinions.push(minion)
          @hasBeenSeen = true
    return false

  checkHasNoTarget: ->
    if @targetMinions.length
      return false
    if @singleBullet && @lastBullet
      @lastBullet.instantKill()
      @lastBullet = null

  checkHasNoBullets: ->
    if !@stopAttackingWhenBulletsAreDead
      return false
    for bullet, idx in @currentBullets by -1
      if bullet._killed
        @currentBullets.splice(idx, 1)
    if @currentBullets.length == 0
      if @shootVFXEntity?
        @shootVFXEntity.kill()
        @shootVFXEntity = null;
      @currentAnim = @anims.idle




  ###
   * Does stuff like applying modifiers to the bullet etc.
  ###
  getBulletSettings: (target) ->
    bulletDamage = @damage;
    bulletSettings =
      target: target
      owner: @getOwner()
      damage: bulletDamage
      damageMethod: @damageMethod
      loopAnim: !!@singleBullet
      spawner: @
      modifiers: @getBulletModifiers()
    if target?
      #Using angle to minion as calculated by tower so only angles that are valid for this tower are used (so laser turret that only shoots in 4 directions works properly)
      if @totalRotationFrames
        bulletSettings.angle = @getAngleToMinion(target)
      else
        #Get angle manually if this tower has no angles for towers like architects which shoot bullets on an angle but don't rotate.
        #Add 180 because bullets are pointing to the left rather than the right
        bulletSettings.angle = ts.game.functions.calcAngleInDegrees(@getBulletSpawnPos(), target.getCenter()) + 180
    if @bulletImageNum?
      bulletSettings.imageNum = @bulletImageNum
    if @bullet
      bulletSettings = _.extend(bulletSettings, bulletConfig[@bullet])
    bulletSettings = @addBulletAnimationState(bulletSettings)
    return bulletSettings;


  getModifiers: ->
    modifiers = []
    if @mods?
      for type in ['bullet', 'tower']
        for name, details of @mods[type]
          mod = ts.game.modPool.getModifier(name, details)
          modifiers.push(mod)
    return modifiers

  getBulletModifiers: ->
    modifiers = []
    if @mods?.bullet?
      for name, details of @mods.bullet
        mod = ts.game.modPool.getModifier(name, details)
        modifiers.push(mod)
    return modifiers

  getBulletSpawnPos: (bulletNum = 0) ->
    spawnPos = _.clone(@getCenter())
    if @bulletSpawnOffsets?
      if Array.isArray(@bulletSpawnOffsets)
        bulletSpawnOffsets = @bulletSpawnOffsets[bulletNum]
      else
        bulletSpawnOffsets = @bulletSpawnOffsets
      bulletSpawnOffsets[@angle]?
      spawnPos.x += bulletSpawnOffsets[@angle].x
      spawnPos.y += bulletSpawnOffsets[@angle].y
    return spawnPos

  addBulletAnimationState: (bulletSettings) ->
    if !@singleBullet || !@lastBullet
      return bulletSettings
    animationState = @lastBullet.getAnimationState()
    bulletSettings.animationState = animationState
    return bulletSettings

  canShoot: ->
    currentTick = ts.getCurrentTick()
    if currentTick - @reloadTicks < @lastShot
      return false
    return true

  shoot: ->
    if @doesNotShoot
      return false
    if !@targetMinions.length
      return false
    if !@canShoot()
      return false
    if @attackAngles? && @angle not in @attackAngles
      return false
    @lastShot = ts.getCurrentTick()
    if ts.game.debugMode
      @shotTimes.push({
        tick: ts.getCurrentTick()
        minionId: @targetMinions[0].id
        minionPos: @targetMinions[0].getCenter()
      })
    if @singleBullet && @lastBullet?
      @lastBullet.instantKill()
      @lastBullet = null
    for minion in @targetMinions
      bulletSettings = @getBulletSettings(minion);
      totalBullets = @totalBullets || 1
      for bulletNum in [0...totalBullets]
        spawnPos = @getBulletSpawnPos(bulletNum)
        ts.log.debug("Spawning bullet ", bulletSettings.imageName, " at pos: ", spawnPos)
        @lastBullet = ts.game.spawnEntity GameEntity.CTYPE.BULLET, spawnPos.x, spawnPos.y, bulletSettings
        @currentBullets.push(@lastBullet)
    @playAttackAnimation();
    if @shootVFX && !@shootVFXEntity
      @shootVFXEntity = @spawnVFX(@shootVFX)
    return true

  playAttackAnimation: ->
    if @totalFramesPerAttack
      @currentAnim = @anims[@angle + "deg-attack"]
      if !@currentAnim
        if ts.isHeadless
          return null
        throw new Error("Can't find anim angle " + @angle + " all anims is: " + @anims)
      @currentAnim.rewind()
      if @anims['attack-loop']
        @currentAnim.onFinished =>
          @currentAnim = @anims['attack-loop']



  ###
   * An injection point for modifiers from other allied towers to improve this tower
  ###
  addBuffs: (auras, owner) ->
    for own name, details of auras
      buff = @loadBuff(name, details)
      buff.setOwner(owner)
      buff.setTarget(@)
      buff.start()
      @buffs.push(buff)

  ###
    * Turns all the described auras in the tower config file into actual aura objects
  ###
  loadBuff: (name, details) ->
    #Remove hyphens and uppercase the letter after them
    name = name.replace(/-(\w)/g, (match, capture) -> capture.toUpperCase())
    firstCap = name.charAt(0).toUpperCase();
    upperCaseName = firstCap + name.substr(1)
    auraName = upperCaseName
    if !AURAS[auraName]?
      throw "No aura of name " + auraName + " found"
    buff = new AURAS[auraName]
    buff = @setupBuff(buff, details)

  setupBuff: (buff, details) ->
    buff.reset.call(buff)
    buff.setup.apply(buff, details)
    return buff

  removeBuffs: (owner) ->
    remainingBuffs = []
    for buff, idx in @buffs
      if buff.owner == owner
        buff.end()
      else
        remainingBuffs.push(buff)
    @buffs = remainingBuffs
    return true

  removeAllBuffs: () ->
    for buff in @buffs
      buff.end()
    @buffs = []

  removeAllModifiers: () ->
    for modifier in @modifiers
      modifier.end()
    @modifiers = []

  getModifierSettings: (type, name, level) ->
    levelSettings = @getLevelSettings(level)
    if levelSettings.mods?[type]?[name]?
      return levelSettings.mods[type][name]
    return null

  getModifierDescriptions: () ->
    descriptions = {}
    for modifier, idx in @getModifiers()
      if modifier.name && modifier.description
        descriptions[modifier.name] = modifier.description
    return descriptions

  getModifierDetails: ->
    ###
      Can't figure out how to get modifier descriptions with fields filled in with 10 / 15 / 20 / 25 / 30 etc yet
      Need to grab the values passed in from the config and then send the values + the description to the frontend to process it
      But can't figure out how to associate the array values in the config with the data values in description.
      TODO: Figure out how to get modifier details for all levels at once
    ###
    descriptions = []
    for modifier, idx in @getModifiers()
      if modifier.name && modifier.description
        descriptions.push(modifier.getDescription())
    return descriptions


  getAuraDescriptions: () ->
    descriptions = []
    if @auras?
      for own name, details of @auras
        buff = @loadBuff(name, details)
        descriptions.push(buff.getDescription())
    return descriptions

  getAuraDetails: () ->
    ## TODO: Make all levels show in aura descriptions
    return @getAuraDescriptions()

  update: ->
    ts.log.debug("Calling update on tower ", @towerType, " at pos: ", @pos)
    super();
    @scanForTargets();
    @checkHasNoTarget()
    @checkHasNoBullets();
    @rotateToTarget()
    @shoot();

  draw: ->
    if !@isVisible()
      return false
    super()
    if @selected
      @drawRange()
      @drawAuraRange()

  select: ->
    super()
    @selectTime = Date.now()

  getAngleToMinion: (minion) ->
    towerCenter = @getCenter()
    minionCenter = minion.getCenter()
    angle = ts.game.functions.calcAngleInDegrees(towerCenter, minionCenter)
    degreesPerRotationFrame = (360 / @totalRotationFrames)
    angle = Math.floor(angle / degreesPerRotationFrame) * degreesPerRotationFrame;
    angle = (angle + 180) % 360 #+180 to make all angles positive and because frames are pointed to the left instead of right
    return angle

  rotateToTarget: ->
    if !@totalRotationFrames || !@targetMinions.length
      return false
    lastAngle = parseInt(@angle, 10)
    angle = @getAngleToMinion(@targetMinions[0])
    if lastAngle != angle
      @angle = angle
      if @currentAnim && @currentAnim.sequence.length > 1 && !@currentAnim.isAnimFinished() && @anims[angle + "deg-attack"] #We are on an attack animation and are not finished so go to attack anim of next angle
        animDelta = @currentAnim.timer.delta()
        @currentAnim = @anims[angle + "deg-attack"]
        @currentAnim.timer.set(-animDelta)
      else
        @currentAnim = @anims[angle + "deg"]

  drawRange: ->
    animationPercent = Math.min(1, (Date.now() - @selectTime) / config.towers.rangeAnimationTime)
    circlePos = {x: @getCenter().x,  y: @getCenter().y}
    circleRadius =  @range * config.tileSize * animationPercent
    graphics = ts.game.graphics;
    graphics.lineStyle(1, 0x000000, 1);
    graphics.beginFill(0x000000, 0.3)
    graphics.drawCircle(circlePos.x, circlePos.y, circleRadius);
    graphics.endFill()

  drawAuraRange: ->
    if !@auraRange then return false
    animationPercent = Math.min(1, (Date.now() - @selectTime) / config.towers.rangeAnimationTime)
    circlePos = {x: @getCenter().x,  y: @getCenter().y}
    circleRadius =  @auraRange * config.tileSize * animationPercent
    graphics = ts.game.graphics;
    graphics.lineStyle(1, 0x101099, 1);
    graphics.beginFill(0x2424C8, 0.3)
    graphics.drawCircle(circlePos.x, circlePos.y, circleRadius);
    graphics.endFill()


  isVisible: ->
    return true #Always visible for now, no fog of war
    if @hasBeenSeen
      return true
    player = null
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (p) =>
      player = p
    if !@getOwner()? || @getOwner().getTeam() != player.getTeam()
      return false
    return true

  canUpgrade: ->
    if !@getNextLevel()?
      return false
    playerId = 0
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player?
        playerId = player.getId()
    if playerId != @getOwner().getId()
      return false
    return true;

  canSell: ->
    playerId = 0
    ts.game.dispatcher.emit gameMsg.getMainPlayer, (player) =>
      if player?
        playerId = player.getId()
    if playerId != @getOwner().getId()
      return false
    return true;

  getStats: ->
    return @getFormattedStats()

  getTotalLevels: () ->
    towerDetails = towerConfig[@towerType]
    return towerDetails.levels.length

  getLevelSettings: (level) ->
    towerDetails = towerConfig[@towerType]
    if ts.game.settings.linearGold
      return towerDetails.linearGoldLevels[level]
    return towerDetails.levels[level]

  getFormattedBaseDamage: (level) ->
    levelSettings = @getLevelSettings(level)
    damage = levelSettings['damage'] || @baseDamage
    if @damageMethod == "percent"
      damage += "%";
    return damage;

  getFormattedBonusDamage: () ->
    bonusDamage = Math.round(@baseDamage * @damageBoost)
    if @damageMethod == "percent"
      bonusDamage += "%"
    return bonusDamage;

  getFormattedAttackSpeed: (level) ->
    levelSettings = @getLevelSettings(level)
    return levelSettings['attackSpeed'] || @baseAttackSpeed

  getFormattedRange: (level) ->
    levelSettings = @getLevelSettings(level)
    range = levelSettings['range'] || @range
    return range

  getFormattedStats: () ->
    damageArray = []; attackSpeedArray = []; rangeArray = [];
    for idx in [0...@getTotalLevels()]
      damageArray.push(@getFormattedBaseDamage(idx))
      attackSpeedArray.push(@getFormattedAttackSpeed(idx))
      rangeArray.push(@getFormattedRange(idx))
    stats = {
      attacks: [@attackMoveTypes.join(' & ')] # Turns it into ['ground & air']
      damage: _.uniq(damageArray)
      damageBoost: [@getFormattedBonusDamage()]
      attackSpeed: _.uniq(attackSpeedArray)
      range: _.uniq(rangeArray)
    }
    return stats

  getNextLevelCost: ->
    if !@getLevelSettings(this.level + 1)
      return 0
    return @getLevelSettings(this.level + 1).cost;

  getSellValue: ->
    towerInfo = towerConfig[@towerType]
    totalCost = towerInfo.cost
    if this.level > 0
      for x in [1..this.level]
        totalCost += @getLevelSettings(x).cost
    sellValue = totalCost * config.towerSellReturnPercent
    return sellValue

  #Don't check for canUpgrade as it comes from a tick
  upgrade: () ->
    nextLevel = @getLevelSettings(@level+1)
    @level += 1
    if @auras? && nextLevel.auras? #Remove any modifiers this tower already has if new ones are to be injected
      @killAuras();
      @mods = {}
    if nextLevel['damage']
      @baseDamage = parseInt(nextLevel['damage'])
      @calculateDamage()
    if nextLevel['attackSpeed']
      @baseAttackSpeed = parseFloat(nextLevel['attackSpeed'])
      @calculateReloadTicks()
    if nextLevel['range']
      @baseRange = parseFloat(nextLevel['range'])
      @calculateRange()
    for attribute in ['mods', 'maxTargets']
      if nextLevel[attribute]
        @[attribute] = nextLevel[attribute]
    if nextLevel.auras? #Install new mods in nearby towers
      @runAuras();
    ts.game.dispatcher.emit gameMsg.upgradedTower, @
    @isUpgrading = false

  #Don't check for canSell as it comes from a tick
  sell: () ->
    ts.game.dispatcher.emit gameMsg.soldTower, @
    @kill()

  kill: ->
    @killAuras();
    @removeAllBuffs();
    @removeAllModifiers();
    super();

  handleHover: (xPos, yPos) ->
    if !@isVisible()
      return false
    super(xPos, yPos)

  handleClick: (xPos, yPos) ->
    if !@isVisible()
      return false
    super(xPos, yPos)

  getSnapshot: (snapshot = {}) ->
    for item in ['baseDamage', 'damageBoost', 'dpsBoost', 'damage', 'baseAttackSpeed', 'attackSpeedBoost', 'reloadTicks', 'lastShot', 'shotTimes', 'range', 'rangeScaled', 'rangeScaledSquared', 'bonusGold', 'level', 'angle']
      snapshot[item] = @[item]
    super(snapshot)

module.exports = Tower
