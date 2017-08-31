module.exports = {
    id: "flamer",
    name: "Flamethrower",
    description: "Shoots a large constant flame dealing damage to all minions in an area. ",
    cost: 110,
    attackSpeed: 6,
    imageName: "flamer.png",
    totalRotationFrames: 36,
    totalFramesPerAttack: 1,
    attackFrames: [1],
    range: 2,
    attackMoveTypes: ['ground', 'air'],
    bullet: "flame",
    singleBullet: true,
    bulletSpawnOffsets: {
      '0': {x: -23, y: -9},
      '10': {x: -24, y: -13},
      '20': {x: -23, y: -16},
      '30': {x: -21, y: -20},
      '40': {x: -19, y: -23},
      '50': {x: -17, y: -25},
      '60': {x: -15, y: -28},
      '70': {x: -11, y: -29},
      '80': {x: -6, y: -30},
      '90': {x: 0, y: -31},
      '100': {x: 6, y: -30},
      '110': {x: 11, y: -29},
      '120': {x: 15, y: -28},
      '130': {x: 17, y: -25},
      '140': {x: 19, y: -23},
      '150': {x: 21, y: -20},
      '160': {x: 23, y: -16},
      '170': {x: 24, y: -13},
      '180': {x: 23, y: -9},
      '190': {x: 23, y: -6},
      '200': {x: 23, y: -2},
      '210': {x: 21, y: 2},
      '220': {x: 18, y: 6},
      '230': {x: 15, y: 8},
      '240': {x: 13, y: 10},
      '250': {x: 9, y: 12},
      '260': {x: 4, y: 13},
      '270': {x: 0, y: 14},
      '280': {x: -4, y: 13},
      '290': {x: -9, y: 12},
      '300': {x: -13, y: 10},
      '310': {x: -15, y: 8},
      '320': {x: -18, y: 6},
      '330': {x: -21, y: 2},
      '340': {x: -23, y: 2},
      '350': {x: -23, y: 6},
    },
    mods: {
      bullet: {
        aoe: [1.3]
      }
    },
    levels: [
      {
        damage: 5
      },
      {
        cost: 110,
        damage: 10.2
      },
      {
        cost: 220,
        damage: 21
      },
      {
        cost: 440,
        damage: 43
      },
      {
        cost: 880,
        damage: 88.2
      },
      {
        cost: 1720,
        damage: 181
      }
    ]
}