# vector object extensions
#
# Extend Sylvester's Vector object with additional functions
#

#= require ../libs/sylvester

# Static functions

# isClockwise
# 
# Determines if object starts at p with velocity v is moving clockwise about the origin
# @returns {Boolean}
Vector.isClockwise = (v, p) ->
  n = p.clockwiseNormal()
  v.component(n) > 0

# directionVector
#
# @param {Number} angle angle in radians or degrees
# @param {String} unit d|r degrees or radians
# @return a 3D vector pointing at ang clockwise from the positive x-axis
Vector.directionVector = (angle, unit='r') ->
  angle *= (Math.PI / 180) if unit == 'd'
  $V([Math.cos(angle), Math.sin(angle), 0])
  
# Instance functions

# to2D
#
# Forces a vector to 2d.  Useful to keep Sylvester functions from 
# breaking when mixing 3d & 2d args.
# @return {Vector} 2d vector
Vector::to2D = ->
  $V([@elements[0], @elements[1]])
  
# mag
#
# Calculates the magnitude (length) of the vector and returns the result 
# @returns {Number}
Vector::mag = ->
  V = @elements
  Math.sqrt(V[0]*V[0] + V[1]*V[1] + V[2]*V[2])
  
# normal
#
# (2D) normal of vector
# @returns {Vector} 
Vector::normal = ->
  $V([-@elements[1], @elements[0], 0])
  
# component
#
# @returns {Number} component of vector in a new basis
Vector::component = (direction) ->
  alpha = Math.atan2 direction.e(2), direction.e(1)
  theta = Math.atan2 @e(2), @e(1)
  @mag() * Math.cos(theta - alpha)
  
# componentVector
#
# component of vector in the basis of direction
# @returns {Vector}
Vector::componentVector = (direction) ->
  direction.toUnitVector().x @component(direction)

# divide
#
# Divides vector by some float
# @returns {Vector}
Vector::divide = (val) ->
  @map (x) -> x / val

# rotate
# 
# Rotates a vector by some amount of radians
# @returns {Vector}
Vector::rotate = (rads) ->
  return this if rads == 0
  x = @elements[0]
  y = @elements[1]
  # set l to the magnitude
  l = @mag()
  return this if l == 0
  
  newang = rads + Math.atan(y, x)
  x1 = l * Math.cos(newang)
  y1 = l * Math.sin(newang)
  $V([x1, y1, 0])
  
# clockwiseNormal
#
# perpendicular vector, by convention
# Note: Identical to normal(), but used in specific circumstances
# @returns {Vector}
Vector::clockwiseNormal = ->
  @normal()
  
# moment
# 
# The moment of the vector about the origin for a particle at point p
# @returns {Number}
Vector::moment = (p) ->
  @clockwiseNormal().dot(p)

