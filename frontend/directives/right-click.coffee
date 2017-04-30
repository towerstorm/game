RightClickDirective = ($parse) ->
  (scope, element, attrs) ->
    fn = $parse(attrs.ngRightClick)
    element.bind "contextmenu", (event) ->
      scope.$apply ->
        event.preventDefault()
        fn(scope, {$event: event})
RightClickDirective.$inject = ['$parse']
angular.module('towerstorm.directives').directive "ngRightClick", RightClickDirective
