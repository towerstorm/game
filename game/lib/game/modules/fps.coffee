class FPS
  constructor: ->
    @current = 0
    @list = 0
    @lastUpdated = Date.now()
    @textObject = null

  getFPS: ->
    return @last

  draw: (font) ->
    if ts.game.hud
      text = "FPS: #{@last}"
      if @textObject
        @textObject.setText(text)
      else
        @textObject = ts.game.hud.drawText(text, 10, 10, "left")

  update: ->
    @current++
    if Date.now() - @lastUpdated >= 1000
      @last = @current
      @current = 0
      @lastUpdated = Date.now()

module.exports = FPS
