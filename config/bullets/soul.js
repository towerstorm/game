module.exports = {
  width: 32,
  height: 32,
  pivot: {
    x: 16,
    y: 16
  },
  offset: {
    x: 16,
    y: 16
  },
  imageName: "soul.png",
  speed: 100,
  idleFrames: 12,
  idleFrameTime: 0.05,
  instantDamage: true,
  instantTravel: true,
  returnToTower: true,
  faceTarget: true,
  animations: [
    {
      dontStartImmediately: true,
      type: 'detonate',
      time: 0.5,
      endWidth: 0,
      endHeight: 0,
      startPos: function() {
        return {
          x: this.targetPos.x,
          y: this.targetPos.y
        };
      },
      endPos: function() {
        return {
          x: this.targetPos.x + 16,
          y: this.targetPos.y + 16
        };
      }
    }
  ]
};