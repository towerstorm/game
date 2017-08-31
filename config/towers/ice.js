module.exports = {
    id: "ice",
    name: "Ice",
    description: "Throws chunks of ice slowing down and damaging a single target.",
    cost: 50,
    range: 3,
    attackMoveTypes: ['ground', 'air'],
    imageName: "ice.png",
    bullet: "iceball",
    levels: [
      {
        damage: 10,
        attackSpeed: 0.6,
        mods: {
          bullet: {
            slow: [3, 20]
          }
        }
      },
      {
        cost: 50,
        damage: 21,
        attackSpeed: 0.7,
        mods: {
          bullet: {
            slow: [3.2, 30]
          }
        }
      },
      {
        cost: 100,
        damage: 42,
        attackSpeed: 0.8,
        mods: {
          bullet: {
            slow: [3.4, 40]
          }
        }
      },
      {
        cost: 200,
        damage: 86,
        attackSpeed: 0.9,
        mods: {
          bullet: {
            slow: [3.6, 50]
          }
        }
      },
      {
        cost: 400,
        damage: 176,
        attackSpeed: 1,
        mods: {
          bullet: {
            slow: [3.8, 60]
          }
        }
      },
      {
        cost: 800,
        damage: 362,
        attackSpeed: 1.1,
        mods: {
          bullet: {
            slow: [4, 70]
          }
        }
      }
    ]
  }