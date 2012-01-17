# Shape class
# Base class for all drawn objects

#= require ./vec

class Shape
  constructor: (x, y, z, opts={}) ->
    @pos = $V([x, y, z])
    @mass = @efficiency = 1.0
    @collisionNormal  = null # vector
    @[x] = val for x, val of opts
    @velocity ?= Vector.Zero(3)
    @displacement ?= Vector.Zero(3)
    @direction ?= Vector.Zero(3)
    
  move: (vec) ->
    @pos = @pos.add(vec)
    
  x: -> @pos.e(1)
  y: -> @pos.e(2)
  z: -> @pos.e(3)
  
  # prototype properties
  toString: -> 
    kvs = for key, val of @ when val? and typeof(val) != 'function'
      if typeof(val) is 'object'
        "#{key} = #{val.inspect()}\n"
      else
        "#{key} = #{val}\n"
    kvs.join("")
  # class-level properties
  
root = exports ? window
root.Shape = Shape