# vector object extensions
#
# Extend Sylvester's Vector object with additional functions
#

#= require ../libs/sylvester

# Static functions

# isClockwise
# 
# Determines if object at p with velocity v is moving clockwise about the origin
# @returns {Boolean}
Vector.isClockwise = (v, p) ->
  n = p.clockwiseNormal()
  v.component(n) > 0

# unitVectorFromAngle
#
# general-purpose function to keep clockwiseNormal() consistent
# @returns {Vector}
Vector.unitVectorFromAngle = (angle) ->
  $V(Math.sin(angle), Math.cos(angle))
  
# Instance functions

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

  