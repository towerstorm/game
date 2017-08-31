module.exports = {
    id: "spikes",
    name: "Spikes",
    description: "",
    cost: 70,
    buildsOnRoads: true,
    attackSpeed: 10,
    imageName: "spikes.png",
    range: 0.6,
    attackMoveTypes: ['ground'],
    zIndex: 5,
    bullet: 'invisible-aoe',
    mods: {
      bullet: {
        aoe: [0.6]
      }
    },
    levels: [
      {
        damage: 2
      },
      {
        cost: 70,
        damage: 4
      },
      {
        cost: 140,
        damage: 8
      },
      {
        cost: 280,
        damage: 17
      },
      {
        cost: 560,
        damage: 35
      },
      {
        cost: 1120,
        damage: 72
      }
    ]
}
