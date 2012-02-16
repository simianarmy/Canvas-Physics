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

### Functions for consistent angular measurements in 2D space ###
# 
# Angular calculations must use the same concept of direction of y-axis 
# in the 2-D space (y measured upwards in cartesian coordinates, 
# but measured downwards in HTML5 Canvas, GL, etc.)
#
# We have to ensure that it ties in correctly with our measure for 
# positive angular displacement, which is ensured with the general-purpose 
# functions: 
# clockwiseNormal(), unitVector() and angleOf()

# clockwiseNormal
#
# perpendicular vector, by convention.
#
# @return {Vector}
Vector::clockwiseNormal = ->
  $V([-@elements[1], @elements[0], 0])

# unitVector
#
# To be used for consistent angular calculations based on direction of y-axis.
# see: unitVector, isClockwise, and clockwiseNormal
Vector::unitVector = (ang) ->
  $V([Math.sin(ang), Math.cos(ang), 0])

# angleOf
#
# To be used for consistent angular calculations based on direction of y-axis.
# see: unitVector, isClockwise, and clockwiseNormal
Vector::angleOf = ->
  Math.atan(@elements[0], @elements[1])

# moment
# 
# The moment of the vector about the origin for a particle at point p
# @returns {Number}
Vector::moment = (p) ->
  @clockwiseNormal().dot(p)
