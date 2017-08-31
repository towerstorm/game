module.exports = {
    id: "super-laser",
    name: "Super Laser",
    description: "Shoots out a pulse of energy which damages and slows all nearby enemies",
    cost: 350,
    attackSpeed: 0.1,
    imageName: "super-laser.png",
    totalFramesPerAttack: 7,
    attackFrames: [0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1, 0],
    bullet: "energy-circle",
    range: 2.5,
    attackMoveTypes: ['ground', 'air'],
    mods: {
      bullet: {
        aoe: [2.5],
        slow: [2, 40]
      }
    },
    levels: [
      {
        damage: 200
      },
      {
        cost: 350,
        damage: 410,
        mods: {
          bullet: {
            aoe: [2.5],
            slow: [2, 50]
          }
        }
      },
      {
        cost: 700,
        damage: 830,
        mods: {
          bullet: {
            aoe: [2.5],
            slow: [2, 60],
          }
        }
      },
      {
        cost: 1400,
        damage: 1670,
        mods: {
          bullet: {
            aoe: [2.5],
            slow: [2, 70]
          }
        }
      },
      {
        cost: 2800,
        damage: 3320,
        mods: {
          bullet: {
            aoe: [2.5],
            slow: [2, 80]
          }
        }
      },
      {
        cost: 5600,
        damage: 6700,
        mods: {
          bullet: {
            aoe: [2.5],
            slow: [2, 90]
          }
        }
      }
    ]
}
