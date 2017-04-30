_ = require 'lodash'

JQueryMock = ->


  jQuery = (selector, context) ->
    new jQuery.fn.init(selector, context)


  jQuery.fn = jQuery.prototype = 
    init: (selector, context) ->
      @currentHTML = selector
     

  appendTo = (attached) ->
    if !@insertedHTML?
      @insertedHTML = {}

    @insertedHTML[attached] += @currentHTML
    @currentHTML = ""  

  jQuery.fn.appendTo = _.bind(appendTo, jQuery.fn);

      

  return jQuery
  

module.exports = JQueryMock