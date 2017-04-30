EnterFocuses = ($document) ->
  details =
    restrict: 'AE'
    link: ($scope, element, attrs) ->
      $document.bind "keydown keypress", (event) ->
        if event.which == 13 && (!document.activeElement || document.activeElement.id != element[0].id)
          element[0].focus()
          event.stopPropagation()
          event.preventDefault()
      element.bind "keydown keypress", (event) ->
        if event.which == 13 && element[0].value == ''
          element[0].blur()
          event.stopPropagation()
          event.preventDefault()
        if event.which == 27
          element[0].blur()
  return details
EnterFocuses.$inject = ['$document']
angular.module('towerstorm.directives').directive "enterFocuses", EnterFocuses
