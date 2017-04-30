module.exports = {
    id: "fire",
    name: "Volcano",
    description: "Throws out flaming rocks that deal damage to all minions in an area.",
    race: "elementals",
    cost: 350,
    attackSpeed: 0.66,
    imageName: "fire.png",
    range: 4.5,
    attackMoveTypes: ['ground'],
    damageType: 'magical',
    bullet: 'fireball',
    mods: {
      bullet: {
        aoe: [1.5]
      }
    },
    levels: [
        {
          damage: 260
        },
        {
          cost: 350,
          damage: 532
        },
        {
          cost: 700,
          damage: 1092
        },
        {
          cost: 1400,
          damage: 2240
        },
        {
          cost: 2800,
          damage: 4600
        },
        {
          cost: 5600,
          damage: 9400
        }
    ]
}
