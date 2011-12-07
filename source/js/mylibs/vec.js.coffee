# vector object extensions
#
# Extend Sylvester's Vector object with additional functions
#

#= require ../libs/sylvester

# mag
#
# Calculates the magnitude (length) of the vector and returns the result 
# @returns {Number}
Vector::mag = ->
  V = @elements
  Math.sqrt(V[0]*V[0] + V[1]*V[1] + V[2]*V[2])
  
# normal
#
# @returns {Vector} (2D) normal of vector
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
# @returns {Vector} component of vector in the basis of direction
Vector::componentVector = (direction) ->
  direction.toUnitVector().x @component(direction)

# divide
#
# Divides vector by some float
# @returns {Vector}
Vector::divide = (val) ->
  @map (x) -> x / val