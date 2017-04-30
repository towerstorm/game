

Number::map = (istart, istop, ostart, ostop) ->
  ostart + (ostop - ostart) * (this - istart) / (istop - istart)

Number::limit = (min, max) ->
  Math.min max, Math.max(min, this)

Number::round = (precision) ->
  precision = 10 ** (precision or 0)
  Math.round(this * precision) / precision

Number::floor = ->
  Math.floor this

Number::ceil = ->
  Math.ceil this

Number::toInt = ->
  this | 0

Number::toRad = ->
  this / 180 * Math.PI

Number::toDeg = ->
  this * 180 / Math.PI

Array::erase = (item) ->
  i = @length
  while i--
    if @[i] == item
      @splice i, 1
  this

Array::eraseSingle = (item) ->
  i = @length
  while i--
    if @[i] == item
      @splice i, 1
      return this
  this

Array::random = ->
  @[Math.floor(Math.random() * @length)]

Function::bind = Function::bind or (bind) ->
  self = this
  ->
    args = Array::slice.call(arguments)
    self.apply bind or null, args
    
