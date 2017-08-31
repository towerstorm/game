module.exports = {
    id: "laser-beam",
    name: "Laser Beam",
    description: "Shoots a single beam in a line damaging all enemies it passes through.",
    cost: 60,
    attackSpeed: 0.25,
    imageName: "laser-beam.png",
    totalRotationFrames: 36,
    totalFramesPerAttack: 6,
    attackFrames: [1, 2, 3, 4, 5, 6],
    range: 2.5,
    attackMoveTypes: ['ground', 'air'],
    bullet: "laser",
    bulletSpawnOffsets: {
      '0': {x: -18, y: -9},
      '90': {x: 2, y: -27},
      '180': {x: 21, y: -9},
      '270': {x: 2, y: 10},
    },
    attackAngles: [0, 90, 180, 270],
    mods: {
      bullet: {
        'box-aoe': [16]
      }
    },
    levels: [
      {
        damage: 80
      },
      {
        cost: 60,
        damage: 164
      },
      {
        cost: 120,
        damage: 336
      },
      {
        cost: 240,
        damage: 688
      },
      {
        cost: 480,
        damage: 1412
      },
      {
        cost: 960,
        damage: 1894
      }
    ]
}