# vector object extensions
#
# Extend Sylvester's Vector object with additional functions
#

#= require ../libs/sylvester

# Static functions

# NB: MAY CONFLICT WITH unitVector() function!
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
  
# rotateClockwise
# @param {Number} angle amount to rotate vector in radians
Vector::rotateClockwise = (angle) ->
  return this if angle == 0
  x = @e(1)
  y = @e(2)
  l = Math.sqrt(x*x + y*y)
  return this if l == 0
  
  # set newangle to angle + atan2(y,x)
  newangle = angle + Math.atan2(y, x)
  x1 = l * Math.cos(newangle)
  y1 = l * Math.sin(newangle)
  $V([x1, y1, 0])
  
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
# isClockwise(), clockwiseNormal(), Vector.unitVector() and angleOf()

# isClockwise
# 
# Determines if point p with vector v has direction clockwise about the origin
# @param {Vector} p point
# @param {Vector} v vec
# @returns {Boolean}
Vector.isClockwise = (p, v) ->
  n = p.clockwiseNormal()
  v.component(n) > 0

# unitVector
#
# @param {Number} ang angle of rotation (radians) from x-axis
# @return {Vector} representing the specfied rotation
Vector.unitVector = (ang) ->
  $V([Math.sin(ang), Math.cos(ang), 0])

# clockwiseNormal
#
# perpendicular vector, by convention.
#
# @return {Vector}
Vector::clockwiseNormal = ->
  $V([-@elements[1], @elements[0], 0])

# angleOf
#
# To be used for consistent angular calculations based on direction of y-axis.
# see: unitVector, isClockwise, and clockwiseNormal
Vector::angleOf = ->
  Math.atan2(@elements[0], @elements[1])

# moment
# 
# The moment of the vector about the origin for a particle at point p
# @returns {Number}
Vector::moment = (p) ->
  @clockwiseNormal().dot(p)
