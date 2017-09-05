module.exports = {
  name: "Deep Space Collision",
  description: "3 vs 3 PvP map",
  background: "deep-space-collision.png",
  backgroundWidth: 1728,
  backgroundHeight: 1056,
  width: 34,
  height: 20,
  startingStats: {
    souls: 1000
  },
  buildRestrictions: {
    '1': {
      x: {
        min: 0,
        max: 15
      }
    },
    '2': {
      x: {
        min: 18,
        max: 33
      }
    }
  },
  takenPositions: {
    '0': {
      '4': 2,
      '8': 2,
      '17': 2,
    },
    '3': {
      '13': 2,
      '14': 2,
    },
    '4': {
      '0': 2,
      '11': 2,
      '12': 2,
      '14': 2,
    },
    '5': {
      '11': 2,
      '12': 2,
    },
    '9': {
      '16': 2,
    },
    '11': {
      '15': 2,
      '16': 2,
    },
    '12': {
      '14': 2,
      '15': 2,
      '16': 2,
    },
    '13': {
      '3': 2,
      '4': 2,
      '14': 2,
    },
    '14': {
      '3': 2,
      '4': 2,
    },
    '15': {
      '16': 2,
    },
    '18': {
      '3': 2,
    },
    '19': {
      '11': 2,
      '15': 2,
      '16': 2,
    },
    '20': {
      '15': 2,
      '16': 2,
    },
    '21': {
      '3': 2,
      '4': 2,
    },
    '22': {
      '3': 2,
      '4': 2,
    },
    '24': {
      '3': 2,
    },
    '26': {
      '13': 2,
    },
    '27': {
      '14': 2,
      '15': 2,
    },
    '28': {
      '14': 2,
      '15': 2,
    },
    '29': {
      '5': 2,
      '6': 2,
      '18': 2,
    },
    '30': {
      '5': 2,
      '6': 2,
    },
    '33': {
      '15': 2,
    },
  },
  castles: [
    {x: 1, y: 1, team: 0, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'crusaders-red.png' },
    {x: 9, y: 6, team: 0, health: 10, boosts: {speed: 0.2, health: 0.2}, imageName: 'crusaders-red.png' },
    {x: 3, y: 9, team: 0, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'crusaders-red.png' },
    {x: 6, y: 10, team: 0, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'crusaders-red.png' },
    {x: 9, y: 9, team: 0, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'crusaders-red.png' },
    {x: 12, y: 10, team: 0, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'crusaders-red.png' },
    {x: 6, y: 13, team: 0, health: 10, boosts: {speed: 0.3, health: 0.3}, imageName: 'crusaders-red.png' },
    {x: 1, y: 18, team: 0, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'crusaders-red.png' },
    {x: 1, y: 10, team: 0, health: 20, boosts: {speed: 0.1, health: 0.1}, decay: {start: 60 * 45, tick: 10}, imageName: 'crusaders-red-final.png', size: {x: 128, y: 128}, offset: {x: 40, y: 64}, final: true },
    {x: 32, y: 1, team: 1, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'shadow-blue.png' },
    {x: 27, y: 6, team: 1, health: 10, boosts: {speed: 0.3, health: 0.3}, imageName: 'shadow-blue.png' },
    {x: 30, y: 9, team: 1, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'shadow-blue.png' },
    {x: 27, y: 10, team: 1, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'shadow-blue.png' },
    {x: 24, y: 9, team: 1, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'shadow-blue.png' },
    {x: 21, y: 10, team: 1, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'shadow-blue.png' },
    {x: 24, y: 13, team: 1, health: 10, boosts: {speed: 0.2, health: 0.2}, imageName: 'shadow-blue.png' },
    {x: 32, y: 18, team: 1, health: 10, boosts: {speed: 0.1, health: 0.1}, imageName: 'shadow-blue.png' },
    {x: 32, y: 9, team: 1, health: 20, boosts: {speed: 0.1, health: 0.1}, decay: {start: 60 * 45, tick: 10}, imageName: 'shadow-blue-final.png', size: {x: 128, y: 128}, offset: {x: 40, y: 72}, final: true },
  ],
  spawnPoints: [
    {
      x: 15, 
      y: 1, 
      team: 2,
    },
    {
      x: 15, 
      y: 6, 
      team: 2,
    },
    {
      x: 15, 
      y: 10, 
      team: 2,
    },
    {
      x: 15, 
      y: 13, 
      team: 2,
    },
    {
      x: 15, 
      y: 18, 
      team: 2,
    },
    {x: 18, y: 1, team: 1},
    {x: 18, y: 6, team: 1},
    {x: 18, y: 9, team: 1},
    {x: 18, y: 13, team: 1},
    {x: 18, y: 18, team: 1},
  ],
  nodePaths: [
    [
      {x: 15, y: 1},
      {x: 1, y: 1},
      {x: 1, y: 10},
    ],
    [
      {x: 15, y: 6},
      {x: 9, y: 6},
      {x: 9, y: 1},
      {x: 1, y: 1},
      {x: 1, y: 10},
    ],
    [
      {x: 15, y: 10},
      {x: 12, y: 10},
      {x: 12, y: 9},
      {x: 9, y: 9},
      {x: 9, y: 10},
      {x: 6, y: 10},
      {x: 6, y: 9},
      {x: 3, y: 9},
      {x: 3, y: 10},
      {x: 1, y: 10},
    ],
    [
      {x: 15, y: 13},
      {x: 6, y: 13},
      {x: 6, y: 18},
      {x: 1, y: 18},
      {x: 1, y: 10},
    ],
    [
      {x: 15, y: 18},
      {x: 1, y: 18},
      {x: 1, y: 10},
    ],
    [
      {x: 18, y: 1},
      {x: 32, y: 1},
      {x: 32, y: 9},
    ],
    [
      {x: 18, y: 6},
      {x: 27, y: 6},
      {x: 27, y: 1},
      {x: 32, y: 1},
      {x: 32, y: 9},
    ],
    [
      {x: 18, y: 9},
      {x: 21, y: 9},
      {x: 21, y: 10},
      {x: 24, y: 10},
      {x: 24, y: 9},
      {x: 27, y: 9},
      {x: 27, y: 10},
      {x: 30, y: 10},
      {x: 30, y: 9},
      {x: 32, y: 9},
    ],
    [
      {x: 18, y: 13},
      {x: 24, y: 13},
      {x: 24, y: 18},
      {x: 32, y: 18},
      {x: 32, y: 9},
    ],
    [
      {x: 18, y: 18},
      {x: 32, y: 18},
      {x: 32, y: 9},
    ]
  ]
}
