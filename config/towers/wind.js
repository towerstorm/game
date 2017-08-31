module.exports = {
    id: "wind",
    name: "Wind",
    description: "A Raging whirlwind that slows enemies and deals damage to them as they walk through it.",
    cost: 50,
    buildsOnRoads: true,
    attackSpeed: 10,
    imageName: "wind.png",
    bullet: 'invisible-aoe',
    idleFrames: 16,
    range: 0.6,
    attackMoveTypes: ['ground', 'air'],
    mods: {
      bullet: {
        aoe: [0.7]
      }
    },
    levels: [
      {
        damage: 1.4,
        mods: {
          bullet: {
            slow: [0.1, 10]
          }
        }
      },
      {
        cost: 50,
        damage: 2.8,
        mods: {
          bullet: {
            slow: [0.1, 15]
          }
        }
      },
      {
        cost: 100,
        damage: 5.8,
        mods: {
          bullet: {
            slow: [0.1, 20]
          }
        }
      },
      {
        cost: 200,
        damage: 12,
        mods: {
          bullet: {
            slow: [0.1, 25]
          }
        }
      },
      {
        cost: 400,
        damage: 25,
        mods: {
          bullet: {
            slow: [0.1, 30]
          }
        }
      },
      {
        cost: 800,
        damage: 50,
        mods: {
          bullet: {
            slow: [0.1, 35]
          }
        }
      }
    ]
}
