module.exports = {
    id: "soul-eater",
    name: "Soul Eater",
    description: "Devours minion souls, dealing damage based on how many souls they have. Long range and very slow attack speed.",
    race: "shadow",
    cost: 350,
    attackSpeed: 0.04,
    damageMethod: "souls",
    imageName: "soul-eater.png",
    totalFramesPerAttack: 7,
    attackFrames: [1, 2, 3, 4, 5, 6, 7],
    attackLoopFrames: [4, 5, 6, 7],
    range: 6,
    attackMoveTypes: ['ground', 'air'],
    damageType: 'pure',
    shootVFX: 'soulSucking',
    bullet: "soul",
    bulletSpawnOffsets: {
      '0': {x: 0, y: 3}
    },
    stopAttackingWhenBulletsAreDead: true,
    levels: [
      {
        maxTargets: 1,
        damage: 1
      },
      {
        cost: 350,
        damage: 2
      },
      {
        cost: 700,
        damage: 3
      },
      {
        cost: 1400,
        damage: 4
      },
      {
        cost: 2800,
        damage: 5
      },
      {
        cost: 5600,
        damage: 6
      }
    ]
}