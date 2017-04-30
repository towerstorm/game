
var config = {
  logToConsole: true,
  datadog: {
    api_key: process.env.DATADOG_API_KEY,
    app_key: process.env.DATADOG_APP_KEY 
  }
};

module.exports = config;