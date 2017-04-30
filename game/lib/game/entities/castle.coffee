GameEntity = require("./game-entity.coffee")

config = require("config/general")
gameMsg = require("config/game-messages")

class Castle extends GameEntity
  name: "castle"
  ctype: GameEntity.CTYPE.CASTLE
    
  constructor: (x, y, settings) ->
    @reset()
    super(x, y, settings)
    teamColor = if settings.team == 0 then 'red' else 'blue'
    @size = settings.size || {x: 64, y: 80}
    @animSheet = ts.game.cache.getAnimationSheet("castles/" + @imageName, @size.x, @size.y, config.castles.zIndex);
    @addAnim("idle", 0.1, [0])
    @addAnim("rubble", 0.1, [1])
    @offset = settings.offset || {x: (@size.x - 48) / 2, y: ((@size.y - 48) / 2) + 16}
    @maxHealth = @health
    @canBeSelected = true
    @healthBar.height = 6
    if !@visible #Update drawpos manually so health bar is drawn correctly as it doesn't not update when an entitiy is not visible
      @drawPos.x = @last.x - @offset.x + ts.game.paddingLeft;
      @drawPos.y = @last.y - @offset.y + ts.game.paddingTop;
    @updateHealthBarHealth()
    if @animSheet
      @animSheet.setTint(config.tint.default)

  reset: ->
    super()
    if @healthBarImage
      ts.system.container.removeChild(@healthBarImage)
    @team = 0
    @health = 0
    @maxHealth = 0
    @totalDecay = 0
    @healthChanged = true
    @canBeSelected = false
    @boosts = {}
    @healthBar = {}
    @decay = {}
    @healthBarImage = null
    @castleType = null
    @final = false
    @timeOfDeath = 0

  draw: ->
    if @_killed
      timeSinceDeath = Date.now() - @timeOfDeath
      deathFadeTime = config.castles.deathFadeTime * 1000
      if timeSinceDeath >= deathFadeTime
        @animSheet.setAlpha(0)
      else
        @animSheet.setAlpha(1 - (timeSinceDeath / deathFadeTime))
    super()
    @drawHealthBar()

  drawHealthBar: ->
    if @health <= 0
      if @healthBarImage
        ts.system.container.removeChild(@healthBarImage)
        @healthBarImage = null
      return false

    if !@healthBarImage
      @healthBarImage = new PIXI.Graphics()
      @healthBarImage.zIndex = config.healthBars.zIndex
      ts.system.container.addChild(@healthBarImage)

    if @healthChanged
      borderWidth = 1
      @healthBarImage.clear()

      #Healthy Part (green fill)
      @healthBarImage.beginFill(0x00C800)
      @healthBarImage.drawRect(borderWidth, 0, @healthBar.greenWidth, @healthBar.height + borderWidth * 2)
      @healthBarImage.endFill()

      #Damaged Part (red fill)
      @healthBarImage.beginFill(0xC80000)
      @healthBarImage.drawRect(borderWidth + @healthBar.greenWidth, 0, @healthBar.redWidth, @healthBar.height + borderWidth * 2)
      @healthBarImage.endFill()

      @healthBarImage.lineStyle(borderWidth, 0x000000, 1);
      @healthBarImage.drawRect(0, 0, @healthBar.greenWidth + @healthBar.redWidth + borderWidth * 2, @healthBar.height + borderWidth * 2)
      @healthBarImage.lineStyle(0)
      @healthChanged = false
    return true

  update: ->
    super();
    @updateHealthBarPos();
    @checkDecay();

  updateHealthBarHealth: ->
    @healthChanged = true
    @healthBar.greenWidth = ((@size.x) * (@health / @maxHealth))
    @healthBar.redWidth = ((@size.x) * (1 - (@health / @maxHealth)))

  updateHealthBarPos: ->
    if @healthBarImage
      @healthBarImage.x = @drawPos.x - 1 #-1 for the borderWidth of 1
      @healthBarImage.y = @drawPos.y - 12

  halfHealth: ->
    
  checkDecay: ->
    if !@decay
      return
    decayStartTime = @decay.start
    if !decayStartTime || ts.getCurrentConstantTime() < decayStartTime
      return false
    decayTickTime = @decay.tick
    expectedDecay = Math.ceil((ts.getCurrentConstantTime() - decayStartTime) / decayTickTime)
    if @totalDecay < expectedDecay
      ts.game.dispatcher.emit(gameMsg.castleDecay, this)
      @totalDecay++
      @receiveDamage(1, null)

  receiveDamage: (amount, from) ->
    if @_killed
      return false;
    amount = Math.min(amount, @health)
    ts.game.dispatcher.emit(gameMsg.castleDamage, amount, this)
    super(amount, from)
    @updateHealthBarHealth()
    if !@_killed && @health < @maxHealth / 2 #Check killed again as otherwise animation will go to rubble then back to half health
      @halfHealth()

  kill: ->
    @zIndex = 10;
    @timeOfDeath = Date.now();
    @canBeSelected = false
    if @animSheet
      @animSheet.destroy()
      @animSheet = ts.game.cache.getAnimationSheet("rubble.png", 72, 72, config.castles.rubbleZIndex);
      @addAnim("idle", 0.1, [0])
      @offset = {x: 12, y: 12}
      @currentAnim = @anims.idle
    ts.game.dispatcher.emit(gameMsg.castleDied, this)
    @_killed = true

module.exports = Castle
