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

# Constrains angle within range range, +2pi
# @param {Number} angle radians
# @param {Number} range minimum (default: 0)
# @return {Number} the angle constrained to [range,range+2pi)
Math.radRangeAngle = (angle, range=0) ->
  inc = 2 * Math.PI
  while angle <= range
    angle += inc
  while angle > range+inc
    angle -= inc
    
  angle