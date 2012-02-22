# Circle class
# @extends Shape

#= require ./Shape

class Circle extends Shape
  constructor: (x, y, z, opts) ->
    super
    @name = 'Circle'
    
  MOIFactor: ->
    0.5 * @radius * @radius
  
  toString: ->
    s = "Circle: " + super
    
root = exports ? window
root.Circle = Circle