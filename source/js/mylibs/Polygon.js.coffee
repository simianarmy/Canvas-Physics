# Polygon class
# @extends Shape

#= require ./Shape

class Polygon extends Shape
  # Constructor takes array of Vectors representing points and options object
  constructor: (@points, opts) ->
    super(0, 0, 0, opts)
    @name = 'Polygon'
  
  toString: ->
    pnts = '' 
    pnts += v.inspect() for v in @points
    "Polygon: points: #{pnts}"

root = exports ? window
root.Polygon = Polygon