

angular.module('netService', ['ngResource']).factory('NetService', ['$http', ($http) ->
  noop = ->
  class Net
    lobbyServer:
      port: 8081
      name: ""
      host: ""
      url: ""
    gameServer:
      port: 8082
      name: ""
      host: ""
      url: ""
      code: ""

    constructor: ->
      @gameServer.host  = window.location.hostname
      @lobbyServer.host = window.location.hostname
      @gameServer.url = "//" + @gameServer.host + ":" + @gameServer.port
      @lobbyServer.url = "//" + @lobbyServer.host + ":" + @lobbyServer.port

    createGame: (details, callback) ->
      serverUrl = @gameServer.url + '/game/create?callback=JSON_CALLBACK'
      if details
        if details.mode
          serverUrl += "&mode=" + details.mode
      $http({method: 'JSONP', url: serverUrl})
      .success((data) ->
        callback(null, data);
      )
      .error((err) ->
        console.log "Recieved error connecting to " + serverUrl + " protocol: " + window.location.protocol + " while creating: " + err + ", ", arguments
        callback(new Error("Error connecting to: " + serverUrl))
      )
      return true

    extractServerDetailsFromUrl: (url) ->
      itemMatches = url.match(/\/([a-z0-9\.\-]+)\/([a-zA-Z0-9]+)$/);
      if !itemMatches?
        return null
      @gameServer.name = host = itemMatches[1]
      @gameServer.code = code = itemMatches[2]
      @gameServer.host = host
      return {host, port: @gameServer.port, code}

    getLobbyUrl: ->
      return @lobbyServer.url

    sendData: (method, url, data, callback) ->
      if url.match(/\?/) then sep = "&" else sep = "?"
      if method == "JSONP"
        url += sep + "callback=JSON_CALLBACK"
      $http({method: method, url: url, params: data, withCredentials: true}).success((res) ->
        if res.error?
          return callback(res.error)
        callback(null, res)
      ).error((err) ->
        if !err then err = new Error("Failed to contact server")
        callback(err, null)
      )

    lobbyGet: (path, callback = noop) ->
      @sendData('JSONP', @getLobbyUrl() + path, null, callback)

    lobbyPost: (path, data, callback = noop) ->
      @sendData('JSONP', @getLobbyUrl() + path, data, callback)

    gameGet: (path, callback = noop) ->
      @sendData('JSONP', @gameServer.url + path, null, callback)

    gamePost: (path, data, callback = noop) ->
      @sendData('POST', @gameServer.url + path, data, callback)

    log: (level, message, callback = noop) ->
      @lobbyPost('/log/' + level, {message}, callback)
      
    timing: (stat, time, callback = noop) ->
      @lobbyPost('/timing/', {stat, time}, callback)

  return new Net;
]);