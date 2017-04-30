module.exports = {
    id: "god-of-justice",
    name: "God of Justice",
    description: "Calls down holy light to destroy all enemies.",
    cost: 350,
    attackSpeed: 0.1,
    imageName: "god-of-justice.png",
    bullet: "god-ray",
    range: 5,
    attackMoveTypes: ['ground', 'air'],
    damageType: 'magical',
    mods: {
      bullet: {
        aoe: [1.5]
      }
    },
    levels: [
      {
        damage: 1200
      },
      {
        cost: 350,
        damage: 2460
      },
      {
        cost: 700,
        damage: 5043
      },
      {
        cost: 1400,
        damage: 13800
      },
      {
        cost: 2800,
        damage: 21217
      },
      {
        cost: 5600,
        damage: 45000
      }
    ]
};
