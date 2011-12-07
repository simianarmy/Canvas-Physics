# Shape class
# Base class for all drawn objects

#= require ./vec

class Shape
  constructor: (x, y, z, opts={}) ->
    @pos = $V([x, y, z])
    @mass = @efficiency = 1.0
    @displacement     = null # vector 
    @collisionNormal  = null # vector
    @[x] = val for x, val of opts
    @velocity ?= Vector.Zero()
    
  move: (vec) ->
    @pos = @pos.add(vec)
    
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