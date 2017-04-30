TowerPanelDirective = () ->
  details =
    restrict: 'EA'
    templateUrl: 'templates/game/tower-panel.html'
    scope: {}

    link: (scope, element, attrs) ->
      scope.towerPanels = []
      scope.towerPanel = null
      scope.highlighted = null
      scope.showButtons = false

      scope.safeDigest = (fn) ->
        phase = @$root.$$phase
        if phase is "$apply" or phase is "$digest"
          fn()  if fn and (typeof (fn) is "function")
        else
          @$digest fn

      scope.$on 'game.towerPanel.update', (e, towerPanel) ->
        if ts.game.mode != "TUTORIAL"
          scope.showButtons = true
        scope.towerPanel = towerPanel
        scope.safeDigest()
#        updated = false
#        for name, value of towerPanel
#          if scope.towerPanels[0]?[name] != value
#            updated = true
#        if updated
#          scope.towerPanels = [_.clone(towerPanel)] #1 item array so I can use ng-repeat so cufon works properly.
#          scope.safeDigest()

      scope.$on 'game.towerPanel.visible', (e, visible) ->
        scope.towerPanel.visible = visible
        scope.safeDigest()

      scope.$on 'game.highlighted.update', (e, highlighted) ->
        if highlighted.upgradeButton?
          scope.showButtons = true
        scope.highlighted = highlighted
        scope.safeDigest()

      scope.deselectTower = =>
        ts.game.dispatcher.emit @config.gameMsg.deselectEntity

      scope.clickUpgradeTower = ->
        ts.game.dispatcher.emit config.gameMsg.upgradeSelectedTower

      scope.clickSellTower = ->
        ts.game.dispatcher.emit config.gameMsg.sellSelectedTower

  return details
TowerPanelDirective.$inject = []
angular.module('towerstorm.directives').directive "towerPanel", TowerPanelDirective
