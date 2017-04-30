DevMenuDirective = ($modal, GameService) ->

  details =
    restrict: 'AE'
    scope: {}
    link: ($scope, element, attrs) ->
      modal = null
      $scope.visible = false
      $scope.maps = []
      $scope.options = {"noincome": false}

      listener = new window.keypress.Listener()
      listener.sequence_combo 'd e v', ->
        $scope.show()
#      listener.simple_combo 'esc', ->
#        $scope.hide()

      $scope.show = ->
        $scope.maps = window.config.maps
        modal = $modal.open({templateUrl: 'templates/dev-menu.html', scope: $scope})

      $scope.hide = ->
        modal.close()



  return details;
DevMenuDirective.$inject = ['$modal', 'GameService']
angular.module('towerstorm.directives').directive "devMenu", DevMenuDirective
