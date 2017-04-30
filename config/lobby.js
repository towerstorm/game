var generalConfig;

generalConfig = {
  cookieKey: "express.sid",
  cookieSecret: process.env.COOKIE_SECRET || "notsosecretcookie",
  requestTimeout: 10000,
  matchConfirmTime: 15000,
  logToConsole: true
};

module.exports = generalConfig;
