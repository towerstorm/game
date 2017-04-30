###
  When a bullet has AOE it basically spawns a bullet for each enemy in range then scales the
  bullets damage based on distance from impact. The bullet also applies any other modifiers so
  a tower can have AOE freeze or AOE poison that travels to an area then explodes in AOE awesomeness.
###
DetonationModifier = require("./detonation.coffee")

class BoxAoeModifier extends DetonationModifier
  name: "box-aoe"
  padding: 0              #Extra space around the area to damage, for thin bullets that won't fully encompass minions
  baseDamagePercent: 0

  setup: (@padding = 0, @baseDamagePercent = 100) ->
    super()

  reset: ->
    super()
    @padding = 0
    @baseDamagePercent = 0

  start: ->
    ts.log.debug("Calling BoxAOE start")
    if !@bullet?
      return @end()
    super();
    @dealAoeDamage()
    @end()

  end: ->
    ts.log.debug("Calling BoxAOE end")
    super();

  dealAoeDamage: ->
    damage = @bullet.damage * (@baseDamagePercent / 100)
    startX = @bullet.getImageCenter().x
    startY = @bullet.getImageCenter().y
    ts.log.debug("Calling dealAoeDamage damage in boxAOE ", damage, " startPos ", startX, ",", startY)
    #Whether this bullet is rotated on its side or not to determine what width and height should be calculated from
    hasRotated = if (@bullet.angle == 90 || @bullet.angle == 270) then true else false
    width = if hasRotated then @bullet.height else @bullet.width
    height = if hasRotated then @bullet.width else @bullet.height
    #startX and startY are the center so move back to top left.
    startX -= width / 2
    startY -= height / 2
    startX -= @padding
    startY -= @padding
    width += (@padding * 2)
    height += (@padding * 2)
    damageMethod = null
    attackMoveTypes = null
    if @bullet.spawner?
      damageMethod = @bullet.spawner.damageMethod
      attackMoveTypes = @bullet.spawner.attackMoveTypes
    ts.game.minionManager.damageMinionsInBox(startX, startY, width, height, damage, damageMethod, attackMoveTypes, @bullet.owner.getTeam(), @bullet)

module.exports = BoxAoeModifier
