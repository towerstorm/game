module.exports = {
    id: "gold-booster",
    name: "Gold Booster",
    description: "Increases the gold earned by nearby towers. Also shoots electricity.",
    cost: 80,
    attackSpeed: 0.33,
    imageName: "gold-booster.png",
    idleFrames: 36,
    range: 4,
    auraRange: 3,
    attackMoveTypes: ["ground", "air"],
    bullet: "gold-electricity",
    bulletSpawnOffsets: {
      "0": {x: 2, y: -25}
    },
    levels: [
      {
        damage: 70,
        auras: {
          gold: [0.5]
        }
      },
      {
        cost: 80,
        damage: 144,
        auras: {
          gold: [1]
        }
      },
      {
        cost: 160,
        damage: 294,
        auras: {
          gold: [2.1]
        }
      },
      {
        cost: 320,
        damage: 603,
        auras: {
          gold: [4.5]
        }
      },
      {
        cost: 640,
        damage: 1235,
        auras: {
          gold: [10]
        }
      },
      {
        cost: 1280,
        damage: 2533,
        auras: {
          gold: [21]
        }
      }
    ]
};