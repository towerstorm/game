module.exports = {
    id: "teleporter",
    name: "Teleporter",
    description: "Teleports groups of enemies backwards.",
    race: "architects",
    cost: 350,
    attackSpeed: 0.0625,
    damage: 0,
    imageName: "teleporter.png",
    idleFrames: 36,
    range: 5,
    attackMoveTypes: ['ground', 'air'],
    damageType: 'pure',
    bullet: 'teleport',
    levels: [
      {
        maxTargets: 1,
        mods: {
          bullet: {
            teleport: [100]
          }
        }
      },
      {
        cost: 350,
        maxTargets: 2,
        mods: {
          bullet: {
            teleport: [150]
          }
        }
      },
      {
        cost: 700,
        maxTargets: 3,
        mods: {
          bullet: {
            teleport: [200]
          }
        }
      },
      {
        cost: 1400,
        maxTargets: 4,
        mods: {
          bullet: {
            teleport: [250]
          }
        }
      },
      {
        cost: 2800,
        maxTargets: 5,
        mods: {
          bullet: {
            teleport: [300]
          }
        }
      },
      {
        cost: 5600,
        maxTargets: 6,
        mods: {
          bullet: {
            teleport: [350]
          }
        }
      }
    ]
}