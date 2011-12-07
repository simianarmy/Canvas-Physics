# Circle class
# @extends Shape

#= require ./Shape

class Circle extends Shape
  constructor: (x, y, z, opts) ->
    super
    @name = 'Circle'
    
  toString: ->
    s = "Circle: " + super
    
root = exports ? window
root.Circle = Circle