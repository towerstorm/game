module.exports = {
    id: "earth",
    name: "Earth",
    description: "Throws large boulders that stun entire groups of enemies.",
    cost: 50,
    attackSpeed: 0.16,
    imageName: "earth.png",
    range: 3,
    attackMoveTypes: ['ground'],
    bullet: "boulder",
    levels: [
      {
        damage: 10,
        mods: {
          bullet: {
            aoe: [1],
            stun: [0.5]
          }
        }
      },
      {
        cost: 50,
        damage: 21,
        mods: {
          bullet: {
            aoe: [1],
            stun: [0.7]
          }
        }
      },
      {
        cost: 100,
        damage: 42,
        mods: {
          bullet: {
            aoe: [1],
            stun: [0.9]
          }
        }
      },
      {
        cost: 200,
        damage: 86,
        mods: {
          bullet: {
            aoe: [1],
            stun: [1.1]
          }
        }
      },
      {
        cost: 400,
        damage: 176,
        mods: {
          bullet: {
            aoe: [1],
            stun: [1.3]
          }
        }
      },
      {
        cost: 800,
        damage: 362,
        mods: {
          bullet: {
            aoe: [1],
            stun: [1.5]
          }
        }
      }
    ]
  }