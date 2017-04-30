angular.module('towerstorm', [
  'ngAnimate', 'ngCookies', 'ngRoute', 'ngTouch', 'ui.bootstrap',
  'netService', 'userService', 'analyticsService', 'authService', 'gameService', 'googleAnalyticsService'
  'towerstorm.directives', 'luegg.directives'])
  .config(['$routeProvider', '$rootScopeProvider', '$locationProvider', '$httpProvider', ($routeProvider, $rootScopeProvider, $locationProvider, $httpProvider) ->
    access = authConfig.accessLevels
    $routeProvider
      .when('/home', {templateUrl: 'views/home.html', controller: MenuCtrl, access: access.public})
      .when('/login', {templateUrl: 'views/login.html', controller: LoginCtrl, access: access.public})
      .when('/user/profile', {templateUrl: 'views/profile.html', controller: UserCtrl, access: access.anon })
      .when('/user/friends', {templateUrl: 'views/friends.html', controller: UserFriendsCtrl, access: access.anon })
      .when('/leaderboard', {templateUrl: 'views/leaderboard.html', controller: LeaderboardCtrl, access: access.public })
      .when('/game/select', {templateUrl: 'views/select-game-type.html', controller: MenuCtrl, access: access.anon })
      .when('/game/tutorial', {templateUrl: 'views/tutorial.html', controller: TutorialCtrl, access: access.anon })
      .when('/game/sandbox', {templateUrl: 'views/sandbox.html', controller: SandboxCtrl, access: access.anon })
      .when('/game/ia', {templateUrl: 'views/instant-action.html', controller: InstantActionCtrl, access: access.anon })
      .when('/game/create', {templateUrl: 'views/create-game.html', controller: CreateGameCtrl, access: access.anon})
      .when('/game/join', {templateUrl: 'views/join-game.html', controller: JoinGameCtrl, access: access.anon})
      .when('/game/lobby/:server/:key', {templateUrl: 'views/game-lobby.html', controller: GameLobbyCtrl, access: access.anon})
      .when('/game/play/:server/:key', {templateUrl: 'views/game.html', controller: GameCtrl, access: access.anon})
      .when('/game/summary/:server/:key', {templateUrl: 'views/game-summary.html', controller: GameSummaryCtrl, access: access.anon})
      .when('/lobby/:id', {templateUrl: 'views/lobby.html', controller: LobbyCtrl, access: access.anon})
      .otherwise({redirectTo: '/home'});

    $rootScopeProvider.digestTtl(20)
    interceptor = ["$location", "$q", ($location, $q) ->
      success = (response) ->
        response
      error = (response) ->
        if response.status is 401
          $location.path "/login"
          $q.reject response
        else
          $q.reject response
      (promise) ->
        promise.then success, error
    ]
    $httpProvider.responseInterceptors.push interceptor
  ])
  .run(['$http', '$location', '$rootElement', '$rootScope', '$templateCache', 'AnalyticsService', 'UserService', ($http, $location, $rootElement, $rootScope, $templateCache, AnalyticsService, UserService) ->
    $rootScope.showNav = true

    $rootScope.$on "$locationChangeStart", (event, next, current) ->
      if next.match(/game\/(play|sandbox)/)
        $rootScope.showNav = false
        document.getElementsByTagName('body')[0].style.overflow = 'hidden'
      else
        $rootScope.showNav = true
        document.getElementsByTagName('body')[0].style.overflow = 'auto'

    $rootScope.$on "$routeChangeStart", (event, next, current) ->
      $rootScope.error = null
      if !UserService.authorize(next.access)
        if UserService.isLoggedIn()
          $location.path('/')
        else
          $location.path('/login')

    $rootScope.$on "$routeChangeSuccess", (event, next, current) ->
      AnalyticsService.track('loaded ' + $location.path());
      if typeof ga != "undefined"
        ga('send', 'pageview', $location.path());

    for template in ['create-game', 'friends', 'game', 'game-lobby', 'game-summary', 'home', 'instant-action', 'join-game', 'leaderboard', 'lobby', 'login', 'mobile-test', 'profile', 'select-game-type', 'tutorial']
      $http.get('views/' + template + '.html', {cache: $templateCache})


  ])