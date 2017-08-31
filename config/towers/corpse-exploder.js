module.exports = {
    id: "corpse-exploder",
    name: "Corpse Exploder",
    description: "When a ground minion dies it explodes it's corpse dealing damage to all minions close to it.",
    cost: 150,
    imageName: "corpse-exploder.png",
    doesNotShoot: true,
    attackSpeed: 0.2,
    range: 5,
    attackMoveTypes: ['ground'],
    levels: [
      {
        mods: {
          tower: {
            'corpse-explosion': [25, 1.5]
          }
        }
      },
      {
        cost: 80,
        mods: {
          tower: {
            'corpse-explosion': [30, 1.6]
          }
        }
      },
      {
        cost: 160,
        mods: {
          tower: {
            'corpse-explosion': [35, 1.7]
          }
        }
      },
      {
        cost: 320,
        mods: {
          tower: {
            'corpse-explosion': [40, 1.8]
          }
        }
      },
      {
        cost: 640,
        mods: {
          tower: {
            'corpse-explosion': [45, 1.9]
          }
        }
      },
      {
        cost: 1280,
        mods: {
          tower: {
            'corpse-explosion': [50, 2]
          }
        }
      }
    ]
}