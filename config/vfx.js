/*
  These are effects in the game that aren't bullets.
  spawnDistance - Magnitude distance in pixels away from turret endpoint that this vfx is spawned
  instantDetonate - Should this vfx detonate instantly
 */
var vfx = {
  fireExplosion: {
    width: 32,
    height: 32,
    offset: {
      x: 16,
      y: 16
    },
    imageName: 'fire-explosion.png',
    detonateFrames: 10,
    detonateFrameTime: 0.05,
    spawnDistance: 5,
    instantSpawn: true,
    instantDetonate: true,
    killOnDetonateEnd: true
  },
  godRayRing: {
    width: 236,
    height: 154,
    imageName: 'god-ray-ring.png',
    detonateFrames: 1,
    detonateFrameTime: 1,
    instantSpawn: true,
    instantDetonate: true,
    killOnDetonateEnd: true,
    animations: [
      {
        delay: 0.3,
        time: 1.15,
        startPos: function() {
          var yPos;
          yPos = this.targetPos.y + 32 - 10 - 8;
          if (this.target.moveType === "air") {
            yPos += 16;
          }
          return {
            x: this.targetPos.x - 16,
            y: yPos
          };
        },
        endPos: function() {
          var yPos;
          yPos = this.targetPos.y + 32 - 32 - 8;
          if (this.target.moveType === "air") {
            yPos += 16;
          }
          return {
            x: this.targetPos.x - 48,
            y: yPos
          };
        },
        startWidth: 32,
        endWidth: 96,
        startHeight: 20,
        endHeight: 63
      }
    ]
  },
  corpseExplosion: {
    width: 72,
    height: 72,
    offset: {
      x: 36,
      y: 36
    },
    imageName: 'corpse-explosion.png',
    detonateFrames: 9,
    detonateFrameTime: 0.05,
    instantSpawn: true,
    instantDetonate: true,
    killOnDetonateEnd: true,
  },
  teleport: {
    width: 64,
    height: 128,
    offset: {
      x: 32,
      y: 64
    },
    imageName: "teleport.png",
    detonateFrames: 12,
    detonateFrameTime: 0.03,
    instantSpawn: true,
    instantDetonate: true,
    killOnDetonateEnd: true,
  },
  soulSucking: {
    width: 64,
    height: 64,
    offset: {
      x: 32,
      y: 32
    },
    alpha: 0.8,
    imageName: "soul-sucking.png",
    idleFrames: 8,
    idleFrameTime: 0.05
  }
};

module.exports = vfx
