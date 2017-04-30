###
  A wrapper class for analytics.js script that manages all our tracking
###

angular.module('googleAnalyticsService', ['ng']).factory('GoogleAnalyticsService', ['$rootScope', '$window', '$location', ($rootScope, $window, $location) ->
  track = ->
    if $window._gaq?
      $window._gaq.push(['_trackPageview', $location.path()]);
  $rootScope.$on('$viewContentLoaded', track);
  return null;
])
