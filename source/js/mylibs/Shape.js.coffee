# Shape class
# Base class for all drawn objects

#= require ./vec

class Shape
  constructor: (x, y, z, opts={}) ->
    @pos = $V([x, y, z])
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
    @fixedLinear ?= false
    @fixedAngular ?= true
    @mass ?= 1.0 
    @efficiency ?= 1.0
    
  # move object position by vector amount
  # @param {Vector} vec vector of movement
  # @return {Vector} new position
  move: (vec) ->
    @pos = @pos.add(vec)
    
  # move object position using ahead by some timestep
  # @param {Number} t timestep
  moveByTime: (t) ->
    if !@fixedLinear
      @pos = @locationAfter(t)
      
    if !@fixedAngular
      @setRotation(@rotation + @angularVelocity() * t)
      
  # move object to a position
  # @param {Vector} newPos new position
  moveTo: (newPos) ->
    @pos = newPos.dup()
    
  # determine shape's location after some time
  # @param {Number} t timestep
  # @return {Vector} new position
  locationAfter: (t) ->
    if !@fixedLinear
      @pos.add(@velocity.x(t))
    else
      @pos
  
  # Position getter shortcuts
  x: -> @pos.e(1)
  y: -> @pos.e(2)
  z: -> @pos.e(3)
  
  isRotating: ->
    @angSpeed > 0
    
  isFixedLinear: -> @fixedLinear
  
  isFixedAngular: -> @fixedAngular
    
  # Sets shape's angle of rotation
  # @param {Number} rot (degrees)
  # @param {String} unit d|r default: (d)egrees
  setRotation: (rot, unit='d') ->
    if unit == 'd'
      rot = Math.degreesToRadians(rot)
    @rotation = Math.radRangeAngle(rot, 0) * 180 / Math.PI
  
  radRotation: ->
    Math.degreesToRadians @rotation
  
  angularDirection: -> @rotDirection
  
  # calculate shape's angular velocity
  # @param {String} unit (d)egrees or (r)adians - default: d
  # @return {Number} pseudovector omega with sign dependent 
  # on direction of rotation around axis (clockwiseNormal)
  angularVelocity: (unit='d') ->
    if unit == 'd'
      @angularDirection() * @angSpeed
    else
      (@angularDirection() * @angSpeed) * Math.PI / 180
    
  # set the shape's angular velocity 
  # @param {Number} v degrees/second
  setAngularVelocity: (v) ->
    @rotDirection = if v > 0 then 1 else -1
    @angSpeed = Math.abs(v) # * 180 / Math.PI
    
  setVelocity: (@velocity) ->
    
  # moment of inertia
  MOI: ->
    # Use the shape info to calculate
    @mass * @MOIFactor()
  
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