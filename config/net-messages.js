var netMsg = {
  connect: "connection",
  clientConnect: "connect",
  disconnect: "disconnect",
  authenticate: "authenticate",
  lobby: {
    path: "/lobby",
    create: "create",
    join_: "join",
    getGames: "getGames",
    gameCreated: "gameCreated",
    gameRemoved: "gameRemoved"
  },
  player: {
    details: "playerDetails",
    configure: "configurePlayer",
    refresh: "refresh",
    loaded: "playerLoaded",
    changeName: "changeName",
    changeRace: "changeRace",
    pingTime: "pingTime",
    finished: "finished",
    log: {
      debug: "log.debug"
    }
  },
  game: {
    path: "/game",
    details: "details",
    configure: "configureGame",
    configureBot: "configureBot",
    checkHash: "checkHash",
    ready: "ready",
    start: "start",
    end: "end",
    begin: "begin",
    cancelled: "cancelled",
    didNotConnect: "didNotConnect",
    error: "gameError",
    addBot: "addBot",
    kickPlayer: "kickPlayer",
    kicked: "kicked",
    full: "full",
    "private": "private",
    placeTower: "placeTower",
    upgradeTower: "upgradeTower",
    sellTower: "sellTower",
    spawnTower: "spawnTower",
    getPlayers: "getPlayers",
    getMainPlayerId: "getMainPlayerId",
    sendGold: "sendGold",
    placeMinion: "placeMinion",
    tickData: "tickData",
    syncData: "syncData",
    tickNeeded: "tickNeeded",
    collectGem: "collectGem"
  }
};

module.exports = netMsg;
