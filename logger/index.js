var config = require("config/logger");
var winston = require('winston');

var Dogapi = require("dogapi");
var StatsD = require("node-dogstatsd").StatsD;

if (config.datadog.api_key && config.datadog.app_keya) {
  var datadog = new Dogapi(config.datadog);
  var dogStats = new StatsD("localhost", 8125);
}

var env  = process.env.NODE_ENV || "development";
var hostname = require('os').hostname().replace(/.tsinternal.towerstorm.com/, '').replace(/.towerstorm.com/, '');
var defaultTags = [hostname];


winston.init = function(appName) {
  if (process.env.DEBUG) {
    var currentTime = new Date().getTime();
    winston.add(winston.transports.File, {raw:true, filename: require.main.filename + '/logs/'+currentTime+'.log'});
    if (!config.logToConsole) {
      winston.remove(winston.transports.Console)
    }
  }
  else if (env == "staging") {
    winston.remove(winston.transports.Console)
  }
  else {
    winston.remove(winston.transports.Console)
  }
  winston.setLevels(winston.config.npm.levels)
};

/***
 * Returns custom loggers with tags for when we want to log specific stuff like game information but we can keep all the config in the one spot.
 * @param appName
 * @param tags
 */
winston.getCustomTransports = function (appName, tags) {
  var tagsFormatted = tags != null ? '[' + tags.join('] [') + '] ' : '';
  tags = (tags || []).concat(defaultTags);
  var transports = [];
  if (process.env.DEBUG) {
    transports.push(new (winston.transports.Console)({label: tags.join('][')}))
  }
  return transports
};

winston.timing = function(stat, time, sampleRate, tags) {
    dogStats && dogStats.timing(stat, time, sampleRate, (tags || []).concat(defaultTags));
};

winston.increment = function(stats, sampleRate, tags) {
    dogStats && dogStats.increment(stats, sampleRate, (tags || []).concat(defaultTags));
};

winston.decrement = function(stats, sampleRate, tags) {
    dogStats && dogStats.decrement(stats, sampleRate, (tags || []).concat(defaultTags));
};

winston.gauge = function(stat, value, sampleRate, tags) {
    dogStats && dogStats.gauge(stat, value, sampleRate, (tags || []).concat(defaultTags));
};

winston.histogram = function(stat, value, sampleRate, tags) {
    dogStats && dogStats.histogram(stat, value, sampleRate, (tags || []).concat(defaultTags));
};

winston.update_stats = function(stats, delta, sampleRate, tags) {
    dogStats && dogStats.update_stats(stats, delta, sampleRate, (tags || []).concat(defaultTags));
};

module.exports = winston;
