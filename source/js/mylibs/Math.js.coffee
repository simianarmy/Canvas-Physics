# @module Math
#
# Extensions to the built-in Math module

#= require ./vec

# angularVelocity
#
# Angular velocity of a particle in 2 dimensions
# @param {Vector} v velocity vector of the particle
# @param {Vector} r position vector of the particle (from origin or rotation)
# @param {Float} theta angle of rotation (in radians)
# @return {Float} the angular velocity
Math.angularVelocity = (v, r, theta) ->
  (v.mag() * Math.sin(theta)) / r.mag()
  
# Returns a random float between min and max
# Using Math.round() will give you a non-uniform distribution!
Math.getRandom = (min, max) ->
  (Math.random() * (max - min + 1)) + min

# Returns a random integer between min and max
# Using Math.round() will give you a non-uniform distribution!
Math.getRandomInt = (min, max) ->
  Math.floor(Math.random() * (max - min + 1)) + min

Math.degreesToRadians = (degrees) ->
  degrees * Math.PI / 180
