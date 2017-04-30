module.exports = {
  width: 64,
  height: 128,
  alpha: 1,
  zIndex: 31,
  damageDelay: 0.3,
  detonateFrames: 30,
  detonateFrameTime: 0.05,
  imageName: "god-ray.png",
  instantTravel: true,
  instantDetonate: true,
  speed: 0,
  vfx: ["godRayRing"],
  animations: [
    {
      time: 0.3,
      startPos: function() {
        return {
          x: this.targetPos.x - 32,
          y: 0
        };
      },
      endPos: function() {
        return {
          x: this.targetPos.x - 32,
          y: 0
        };
      },
      startWidth: 64,
      endWidth: 64,
      startHeight: 0,
      endHeight: function() {
        var endHeight;
        endHeight = this.targetPos.y + 32;
        if (this.target.moveType === "air") {
          endHeight += 16;
        }
        return endHeight;
      }
    }
  ]
}