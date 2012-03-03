# Line class
# @extends Shape

#= require ./Shape

class Line extends Shape
  constructor: (sx, sy, ex, ey, opts={}) ->
    super(sx, sy, 0, opts)
    @vec = $V([ex, ey, 0])
    @name = 'Line'

    # Set direction vector from rotation angle
    @setRotation(opts.rotation)
    
    @fixedLinear = (ex == 0 && ey == 0)
    @fixedAngular = @rotation == 0
    
  # endpoint vector
  endpoint: ->
    @pos.add(@vec)
    
  setRotation: (rot) ->
    super(rot)
    if @rotation > 0
      @vec = Vector.unitVector(Math.degreesToRadians(@rotation)).x(@length)
  
  MOIFactor: ->
    @length * @length * 4
    
  toString: ->
    "Line: " + super + " vector: " + @vec.inspect()

  
root = exports ? window
root.Line = Line