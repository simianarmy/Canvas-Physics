# Shape class
# Base class for all drawn objects

#= require ./vec

class Shape
  constructor: (x, y, z, opts={}) ->
    @pos = $V([x, y, z])
    @mass = @efficiency = 1.0
    @collisionNormal  = null # vector
    @[x] = val for x, val of opts
    # initial speed, angular speed, etc
    @velocity ?= Vector.Zero(3)
    @displacement ?= Vector.Zero(3)
    @direction ?= Vector.Zero(3)
    @speed ?= 0
    @rotation ?= 0
    @angSpeed ?= 0
    @rotDirection ?= 1
    
  # move object position
  # @param {Vector} vec vector of movement
  # @return {Vector} new position
  move: (vec) ->
    @pos = @pos.add(vec)
    
  # move object position using ahead by some timestep
  # @param {Number} t timestep
  moveByTime: (t) ->
    @pos = @locationAfter(t)
  
  # determine shape's location after some time
  # @param {Number} t timestep
  # @return {Vector} new position
  locationAfter: (t) ->
    @pos.add(@velocity.x(t))
    
  x: -> @pos.e(1)
  y: -> @pos.e(2)
  z: -> @pos.e(3)
  
  angularDirection: -> @rotDirection
  
  # calculate shape's angular velocity
  # @return {Number} pseudovector omega with sign dependent 
  # on direction of rotation around axis (clockwiseNormal)
  angularVelocity: ->
    @angularDirection() * @angSpeed
    
  # set the shape's angular velocity 
  # @param {Number} v degrees/second
  setAngularVelocity: (v) ->
    @rotDirection = if v > 0 then 1 else -1
    @angSpeed = Math.abs(v) # * 180 / Math.PI
    
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