module.exports = {
    id: "damage-booster",
    name: "Damage Booster",
    description: "Increases the damage of nearby allied towers by 15. Also shoots electricity.",
    cost: 150,
    attackSpeed: 0.2,
    imageName: "damage-booster.png",
    range: 4,
    auraRange: 2.5,
    attackMoveTypes: ["ground", "air"],
    damageType: "pure",
    bullet: "damage-electricity",
    bulletSpawnOffsets: {
      "0":  {
        x: 2,
        y: -29
      }
    },
    levels: [
      {
        damage: 220,
        auras: {
          damage: [8]
        }
      },
      {
        cost: 150,
        damage: 451,
        auras: {
          damage: [17]
        }
      },
      {
        cost: 300,
        damage: 924,
        auras: {
          damage: [35]
        }
      },
      {
        cost: 600,
        damage: 1894,
        auras: {
          damage: [72]
        }
      },
      {
        cost: 1200,
        damage: 3883,
        auras: {
          damage: [147]
        }
      },
      {
        cost: 2400,
        damage: 7960,
        auras: {
          damage: [300]
        }
      }
    ]
}
