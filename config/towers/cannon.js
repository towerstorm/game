module.exports = {
    id: "cannon",
    name: "Cannon",
    description: "A high damage slow firing cannon that only attacks ground enemies.",
    cost: 80,
    attackSpeed: 0.5,
    imageName: "cannon.png",
    totalRotationFrames: 36,
    totalFramesPerAttack: 2,
    attackFrames: [2, 1, 0],
    bullet: "cannon-ball",
    range: 3,
    attackMoveTypes: ['ground'],
    damageType: 'physical',
    bulletSpawnOffsets: {
      '0': {x: -21, y: -9},
      '10': {x: -22, y: -14},
      '20': {x: -21, y: -17},
      '30': {x: -20, y: -20},
      '40': {x: -19, y: -22},
      '50': {x: -17, y: -25},
      '60': {x: -14, y: -27},
      '70': {x: -11, y: -28},
      '80': {x: -8, y: -30},
      '90': {x: 0, y: -31},
      '100': {x: 5, y: -30},
      '110': {x: 11, y: -28},
      '120': {x: 14, y: -27},
      '130': {x: 17, y: -25},
      '140': {x: 19, y: -22},
      '150': {x: 20, y: -20},
      '160': {x: 21, y: -17},
      '170': {x: 22, y: -14},
      '180': {x: 21, y: -9},
      '190': {x: 22, y: -5},
      '200': {x: 21, y: -1},
      '210': {x: 19, y: 1},
      '220': {x: 17, y: 4},
      '230': {x: 14, y: 7},
      '240': {x: 11, y: 8},
      '250': {x: 8, y: 10},
      '260': {x: 4, y: 10},
      '270': {x: 0, y: 11},
      '280': {x: -4, y: 10},
      '290': {x: -8, y: 10},
      '300': {x: -11, y: 8},
      '310': {x: -14, y: 7},
      '320': {x: -17, y: 4},
      '330': {x: -19, y: 1},
      '340': {x: -21, y: -1},
      '350': {x: -22, y: -5},
    },
    levels: [
      {
        damage: 130
      },
      {
        cost: 80,
        damage: 266
      },
      {
        cost: 160,
        damage: 545
      },
      {
        cost: 320,
        damage: 1117
      },
      {
        cost: 640,
        damage: 2289
      },
      {
        cost: 1280,
        damage: 4692
      }
    ]
}
