###
  A wrapper class for analytics.js script that manages all our tracking
###

angular.module('analyticsService', ['ngResource']).factory('AnalyticsService', ['$resource', ($resource) ->
  class Analytics
    lastId = {}

    shouldTrack: ->
      if analytics?
        return true

      return false

    identify: (id, data) ->
      if @shouldTrack() && !_.isEqual(lastId, {id, data})
        analytics.identify(id, data)
        analytics.alias(id)
        lastId = {id, data}

    track: (name, data) ->
      if @shouldTrack()
        analytics.track name, data

  return new Analytics
])