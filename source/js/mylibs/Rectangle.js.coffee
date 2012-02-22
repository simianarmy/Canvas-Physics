# Rectangle class
# @extends Shape

#= require ./Shape

class Rectangle extends Shape
  # @constructor
  # @params {Number} x,y,z center position in as vector components
  # @param {Number} w width
  # @param {Number} h height
  # @param {Object} opts all other properties
  constructor: (x, y, z, w, h, opts) ->
    super(x, y, z, opts)
    @width = w
    @height = h
    @name = 'Rectangle'
    @updateAxes()
      
  toString: ->
    s = "Rectangle: " + super
    s += "\n#{@width} x #{@height}"
    
  updateAxes: ->
    # create major & minor axis vectors
    if @width >= @height
      @majorAxis = $V([@width/2, 0, 0])
      @minorAxis = $V([0, @height/2, 0])
    else
      @majorAxis = $V([0, @height/2, 0])
      @minorAxis = $V([@width/2, 0, 0])
  
  # @return {Vector} top left point, using canvas world coordinates
  origin: ->
    $V([@x()-@width/2, @y()-@height/2, 0])
  
  # @return {Vector} top left point, using cartesian coordinates
  cartesianOrigin: ->
    $V([@x()-@width/2, @y()+@height/2, 0])
    
  # @return {Array} vertex vectors
  vertices: ->
    [@pos.add(@majorAxis.add(@minorAxis)),
    @pos.add(@majorAxis.subtract(@minorAxis)),
    @pos.subtract(@majorAxis.add(@minorAxis)),
    @pos.subtract(@majorAxis.subtract(@minorAxis))]
    
  MOIFactor: ->
    @width*@height*(@width+@height)/12
    
root = exports ? window
root.Rectangle = Rectangle