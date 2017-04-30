
module.exports = {
    id: "speed-booster",
    name: "Speed Booster",
    description: "Increases the attack speed of nearby towers. Also shoots electricity.",
    cost: 50,
    attackSpeed: 1,
    imageName: "speed-booster.png",
    idleFrames: 36,
    range: 3.5,
    auraRange: 1.7,
    bullet: "speed-electricity",
    attackMoveTypes: ["ground", "air"],
    damageType: "pure",
    bulletSpawnOffsets: {
      "0": {x: 1, y: -25}
    },
    levels: [
      {
        damage: 15,
        auras: {
          "attack-speed": [5]
        }
      },
      {
        cost: 50,
        damage: 31,
        auras: {
          "attack-speed": [10]
        }
      },
      {
        cost: 100,
        damage: 63,
        auras: {
          "attack-speed": [15]
        }
      },
      {
        cost: 200,
        damage: 129,
        auras: {
          "attack-speed": [20]
        }
      },
      {
        cost: 400,
        damage: 265,
        auras: {
          "attack-speed": [25]
        }
      },
      {
        cost: 800,
        damage: 543,
        auras: {
          "attack-speed": [30]
        }
      }
    ]
}
