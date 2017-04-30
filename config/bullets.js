/*
  width: width of each frame
  height: height of each frame
  pivot: Used for rotation, it's the point which the image will be rotated around. Set it to center for images that are centered and the right hand side for images that come out from the right towards the left
  hitPointOffset: When this bullet travels towards it's target it will try and hit it with (pos + hitPointOffset) so say an arrow can hit the enemy with it's arrowhead instead of the top left corner.
  instantTravel: Goes to target position instantly upon spawning and detonates
  instantDamage: Deals its damage straight away to teh target. Useful for stuff like shadow ultimate where the bullet kills then returns to base.
  instantDetonate: Detonates immediately as the bullet is spawned
  attachedToTower: Bullet spawns at a point connected to the towers gun so it looks like it's coming out of the tower
    useful for flamethrower / laser type towers where the bullets are always coming out of the turret
  faceTarget: Bullet always rotates towards where it's heading.
  centeredOnTower: Bullet spawns at the towers center point, useful for AOE damage
  stretchToTarget: Bullet stretches or shrinks to exactly where the target is.
  dontDamageTarget: The main target of the tower will not be damaged. This is useful for AOE towers where you want to damage all minions in the radius when it shoots not the specific minion it has targeted.
  targetsLocation: The bullet will fly towards a specific location rather than a minion
  damageDelay: Delay time before minions take damage from this bullet. For weapons with a charge up animation.
  returnToTower: Bullets will set their targetPos to the towers bullet spawn position. Useful with instantTravel as then they spawn on the minion and return to the tower.
 */

var bullets = require("glob-loader!./bullets.pattern")
bullets = _.mapKeys(bullets, function (value, key) { return key.match(/\/([^\/.]+)\./)[1]; })
module.exports = bullets