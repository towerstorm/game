angular.module('authService', []).factory('AuthService', ['$http', '$cookieStore', 'NetService', ($http, $cookieStore, NetService) ->

  class Auth

  return new Auth()


])