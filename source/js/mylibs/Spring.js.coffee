# @class Spring
#
# Represents a spring object with methods for resolving physics

class Spring
  # Spring compressiveness values
  Spring.LOOSE = 1
  Spring.RIGID = 2
  # force value constant
  Spring.BOUNCE = -1
  
  # @param {Vector} pnt1 starting position vector
  # @param {Vector} pnt2 end position vector
  # @param {Vector} v1 velocity at starting point
  # @param {Vector] v2 velocity at end point
  # @param {Object} opts object containing additional properties
  constructor: (@pnt1, @pnt2, v1, v2, @length, opts={}) ->
    @svel = v1.dup()
    @evel = v2.dup()
    @[x] = val for x, val of opts # Save optional properties
    # Set property defaults
    @elasticity       ?= 1
    @damping          ?= 1
    @elasticLimit     ?= 1
    @compressiveness  ?= Spring.LOOSE
    @minLength        ?= 1
    
  # General purpose function to determine force on a particle due to the 
  # spring (at spring endpoing).  
  # This function must be used when neither endpoing of the spring is fixed in place.
  # @return {Vector} force vector
  forceOnEndpoint: ->
    v = @pnt1.subtract(@pnt2)
    d = v.mag()
    return Vector.Zero() if d == 0
    
    # loose elastics have no force when compressed
    if d <= @length
      return Vector.Zero() if @compressiveness == Spring.LOOSE
      
    # apply 2nd elastic limit (inextensible behavior)
    if d >= @elasticLimit*1.2 ||
       d <= @minLength*0.9 ||
       (d <= @length*0.9 and @compressiveness == Spring.RIGID)
      return Spring.BOUNCE
    
    # apply 1st elastic limit (increased force and damping)
    if (d >= @elasticLimit) || (d <= @minLength) || 
      (d <= @length and @compressiveness == Spring.RIGID)
      @elasticity *= 20
      @damping = Math.max(@damping*10, 20)
    
    # calculate force by Hooke's law
    e = d - @length
    vec = v.div(d)
    f = if @damping > 0
      comp = @svel1.subtract(@evel).component(vec)
      @damping * comp + @elasticity * e
    else
      elasticity * e
    
    vec.x(f)

root = exports ? window
root.Spring = Spring
    