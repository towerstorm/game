var schemas = {
  sessions: {
    indexes: ['expires'],
    cols: {}
  },
  users: {
    indexes: ['sanitizedUsername', 'email', 'role', 'elo'],
    cols: {
      id: "",
      username: "",
      sanitizedUsername: "",
      password: "",
      salt: "",
      email: "",
      role: "",
      stormPoints: 0,
      jedPoints: 0,
      elo: 1200,
      experience: 0,
      wins: 0,
      losses: 0,
      level: 1,
      friends: [],
      friendRequests: [],
      lobbyInvitations: [],
      openChatRooms: [],
      privateChatRooms: [],
      activeLobby: null,
      activeQueue: null
    }
  },
  socialLogins: {
    indexes: ['userId'],
    cols: {
      id: "",
      provider: "",
      userId: ""
    }
  },
  games: {
    indexes: ['state', 'code', 'created', 'lastUpdate'],
    cols: {
      id: "",
      created: "",
      lastUpdate: "",
      hostUserId: "",
      chatRoomIds: {},
      version: "",
      serverNum: "",
      code: "",
      state: "",
      settings: "",
      stats: "",
      ticks: {},
      snapshot: {}
    }
  },
  queuers: {
    indexes: ['state', 'matchId'],
    cols: {
      id: "",
      userIds: [],
      confirmedUserIds: [],
      elo: 0,
      joinQueueTime: 0,
      state: null,
      matchId: null,
      game: null
    }
  },
  lobbies: {
    indexes: ['hostUserId', 'queuerId'],
    cols: {
      id: "",
      "public": false,
      active: true,
      hostUserId: "",
      players: [],
      invitedUserIds: [],
      declinedUserIds: [],
      chatRoomId: "",
      queuerId: null
    }
  },
  matches: {
    indexes: [],
    cols: {
      id: "",
      totalAccepts: 0
    }
  },
  chatRooms: {
    indexes: [],
    cols: {
      id: "",
      "private": false,
      userIds: [],
      messages: []
    }
  },
};

module.exports = schemas;
