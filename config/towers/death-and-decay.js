module.exports = {
    id: "death-and-decay",
    name: "Death and Decay",
    description: "Creates an AOE of pestilence that deals a percent of each enemies maximum health in damage.",
    cost: 80,
    damageMethod: "percent",
    attackSpeed: 0.05,
    imageName: "death-and-decay.png",
    range: 2,
    attackMoveTypes: ['ground', 'air'],
    bullet: 'death-and-decay',
    mods: {
      bullet: {
        aoe: [2]
      }
    },
    levels: [
      {
        damage: 5
      },
      {
        cost: 80,
        damage: 7.5
      },
      {
        cost: 160,
        damage: 11.25
      },
      {
        cost: 320,
        damage: 16.85
      },
      {
        cost: 640,
        damage: 25.25
      },
      {
        cost: 1280,
        damage: 38
      }
    ]
}
