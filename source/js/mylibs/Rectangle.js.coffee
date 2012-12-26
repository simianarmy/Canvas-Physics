# Rectangle class
# @extends Shape
# Definition: Rectangle R(u, v, w) is the rectangle centered on the point
# with position vector u and whose sides are given by the perp.vectors 2v and 2w,
# where |v| > |w| (semimajor, semiminor axes.)

#= require ./vec
#= require ./Shape

class Rectangle extends Shape
  # @constructor
  # @params {Number} x,y,z center position in as vector components
  # @param {Number} w width
  # @param {Number} h height
  # @param {Object} opts all other properties
  constructor: (u, v, w, opts) ->
    super(u.e(1), u.e(2), 0, opts)
    @width = v.mag() * 2
    @height = w.mag() * 2
    @displacement = null
    @name = 'Rectangle'
    @updateAxes v, w

  toString: ->
    s = "Rectangle: " + super
    s += "\n#{@width} x #{@height}"

  updateAxes: (v, w) ->
    # create semimajor & semmiminor axis vectors
    if @width >= @height
      @majorAxis = v
      @minorAxis = w
    else
      @majorAxis = w
      @minorAxis = v
    @axis = @majorAxis.toUnitVector()

  # @return {Vector} rectangle origin of current coordinate system
  origin: ->
    if Canvas.topLeftOrigin
      @pos.subtract(@side1().add(@side2()))
    else
      @pos.subtract(@side1().subtract(@side2()))

  center: ->
	  @pos

  side1: ->
    @majorAxis

  side2: ->
    @minorAxis

  setRotation: (rot, unit='d') ->
    if (unit == 'd')
      rot = Math.degreesToRadians(rot)
    # rotate axes around point - force 2D
    major = $V([@majorAxis.e(1), @majorAxis.e(2)])
    minor = $V([@minorAxis.e(1), @minorAxis.e(2)])
    @majorAxis = major.rotate(rot, $V([0, 0])).to3D()
    @minorAxis = minor.rotate(rot, $V([0, 0])).to3D()
    @axis = @majorAxis.toUnitVector()
    super(rot, 'r')
    
  # @return {Array} vertex vectors
  vertices: ->
    [@pos.add(@majorAxis.add(@minorAxis)),
    @pos.add(@majorAxis.subtract(@minorAxis)),
    @pos.subtract(@majorAxis.add(@minorAxis)),
    @pos.subtract(@majorAxis.subtract(@minorAxis))]

  MOIFactor: ->
    @width*@height*(@width+@height)/12
    
  normal: ->
    $V([-@axis.elements[1], @axis.elements[0], 0]).toUnitVector()

root = exports ? window
root.Rectangle = Rectangle
