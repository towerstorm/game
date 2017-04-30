InfoPanelDirective = ($sce) ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game/info-panel.html'
    scope: {}

    link: (scope, element, attrs) ->
      scope.infoPanels = []
      scope.infoPanel = null
      scope.highlighted = null
      scope.showButtons = false

      scope.safeDigest = (fn) ->
        phase = @$root.$$phase
        if phase is "$apply" or phase is "$digest"
          fn()  if fn and (typeof (fn) is "function")
        else
          @$digest fn


      scope.to_trusted = (htmlCode) ->
        return $sce.trustAsHtml(htmlCode)

      scope.$on 'game.infoPanel.update', (e, infoPanel) ->
        if ts.game.mode != "TUTORIAL"
          scope.showButtons = true
        scope.infoPanel = infoPanel
        scope.safeDigest()

      scope.$on 'game.infoPanel.visible', (e, visible) ->
        scope.infoPanel.visible = visible
        scope.safeDigest()

      scope.$on 'game.highlighted.update', (e, highlighted) ->
        if highlighted.upgradeButton?
          scope.showButtons = true
        scope.highlighted = highlighted
        scope.safeDigest()

  return details
InfoPanelDirective.$inject = ['$sce']
angular.module('towerstorm.directives').directive "infoPanel", InfoPanelDirective
