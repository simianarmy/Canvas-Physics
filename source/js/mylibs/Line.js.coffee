# Line class
# @extends Shape

#= require ./Shape

class Line extends Shape
  constructor: (sx, sy, ex, ey, opts) ->
    super(sx, sy, 0, opts)
    @vec = $V([ex, ey, 0])
    @name = 'Line'
  
  toString: ->
    "Line: " + super + " vector: " + @vec.inspect()

root = exports ? window
root.Line = Line