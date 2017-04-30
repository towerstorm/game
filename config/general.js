var general = {
  messageTimeout: 5,
  hqxImageScaling: true,
  gemExpiryTime: 15,
  towerSellReturnPercent: 0.75,
  highlightFlashRate: 1,
  tileSize: 48,
  gameWidth: 816,
  gameHeight: 624,
  timeBeforeFastForward: 0.5,
  maxMinions: 6,
  peaceTime: 60,
  states: {
    none: "NONE",
    init: "INIT",
    lobby: "LOBBY",
    selection: "SELECTION",
    started: "STARTED",
    begun: "BEGUN",
    finished: "FINISHED"
  },
  player: {
    defaultStartingStats: {
      income: 10,
      gold: 250,
      health: 40
    },
    incomeCollectTime: 1,
    incomeMultiplierPerRound: 5
  },
  text: {
    zIndex: 100
  },
  tint: {
    "default": '0xdddddd',
    highlight: '0xffffff'
  },
  fogOfWar: {
    zIndex: 90
  },
  sfx: {
    volume: 0.5
  },
  towers: {
    width: 64,
    height: 64,
    zIndex: 20,
    attackSpeedBoostCap: 100,
    damageBoostCap: 200,
    suicideTime: 3,
    rangeAnimationTime: 200,
    rangeZIndex: 35
  },
  towerOverlay: {
    zIndex: 25
  },
  minionOverlay: {
    zIndex: 25
  },
  minions: {
    width: 64,
    height: 64,
    zIndex: 20,
    upgradeHealthIncreaseMultiplier: 3.1,
    upgradeCostIncreaseMultiplier: 2.5,
    upgradeIncomeIncreaseMultiplier: 2.3,
    upgradeDamageIncreaseMultiplier: 1.5,
    upgradeValueIncreaseMultiplier: 3,
    costUpgradeRatio: 5,
    groundShadowOpacity: 0.5,
    airShadowOpacity: 0.3,
    groundShadowDistance: -20,
    airShadowDistance: 0,
    groundVerticalOffset: 8,
    airVerticalOffset: 32,
    shadowZIndex: 10,
    suicideTime: 3
  },
  bullets: {
    defaultSpeed: 400,
    zIndex: 30
  },
  vfx: {
    zIndex: 30
  },
  gems: {
    floatSpeed: 0.5,
    floatMax: 5,
    zIndex: 20
  },
  doodads: {
    zIndex: 4
  },
  spawnPoints: {
    opacityChange: 0.02,
    minOpacity: 0.5,
    maxOpacity: 1
  },
  castles: {
    zIndex: 20,
    rubbleZIndex: 10,
    deathFadeTime: 3
  },
  healthBars: {
    zIndex: 35
  },
  graphics: {
    zIndex: 40
  },
  modes: {
    survival: "SURVIVAL",
    pvp: "PVP",
    tutorial: "TUTORIAL",
    sandbox: "SANDBOX",
  }
};

module.exports = general
