# @module Canvas
#
# Module for retained mode drawing functions

Canvas = (() ->
  # dependencies
  
  # private properties and methods
  
  # optionally one-time init procedures
  
  # public API -- constructor
  # @param {DOMElement} canvasEl the canvas dom element object
  # @param {String} @mode the canvas drawing mode (2d | 3d) (default: 2d)
  Constr = (canvasEl, @mode='2d') ->
    @ctxt = canvasEl.getContext(@mode)
    @width = canvasEl.width
    @height = canvasEl.height
    @worldView = true # Default origin top left
  
  context = () -> @ctxt
  
  # Set the origin of the canvas
  # @param {String} id (topleft | bottomleft)
  setOrigin = (id) ->
    if @worldView && (id == 'bottomleft')
      # translate world for origin at bottom left
      @ctxt.translate(0, @height)
      @ctxt.scale(1, -1)
      @worldView = false
    else if !@worldView
      # bottom left is default
      @ctxt.scale(1, -1)
      @ctxt.translate(0, -@height)
      @worldView = true
  
  # @return true if drawing with world view coordinates (default = true)
  inWorldView = () ->
    @worldView
    
  # Draw a circle on the canvas
  # @param {Circle} c a Circle object
  drawCircle = (c) ->
    @drawCircleAt c.x(), c.y(), c.radius, c

  # Draw circle from coordinates and radius
  drawCircleAt = (x, y, radius, opts) ->
    @ctxt.fillStyle = opts.color if opts.color?
    @ctxt.beginPath()
    @ctxt.arc(x, y, radius, 0, Math.PI*2, true);
    @ctxt.closePath();
    @ctxt.fill();
    
  # Draw a line on the canvas
  # @param {Line} line a Line object
  drawLine = (line) ->
    endpoint = line.pos.add(line.vec)
    @ctxt.beginPath()
    @ctxt.moveTo line.pos.e(1), line.pos.e(2)
    @ctxt.lineTo endpoint.e(1), endpoint.e(2)
    @ctxt.stroke()
    @ctxt.closePath()
    
  # Draw an ellipse
  # @param {Shape} a Shape object with a position
  # @param {Number} ellipse width
  # @param {Number} ellipse height
  drawEllipse = (c, width, height) ->
    centerX = c.x()
    centerY = c.y()
    @ctxt.beginPath();
    @ctxt.moveTo(centerX, centerY - height/2) # A1
    @ctxt.bezierCurveTo(
      centerX + width/2, centerY - height/2, # C1
      centerX + width/2, centerY + height/2, # C2
      centerX, centerY + height/2) # A2
    @ctxt.bezierCurveTo(
      centerX - width/2, centerY + height/2, # C3
      centerX - width/2, centerY - height/2, # C4
      centerX, centerY - height/2) # A1
    @ctxt.stroke()
    @ctxt.closePath();
  
  # Draw a rectangle
  # @param {Shape} a Rectangle object
  # @param {Object} opts draw options
  drawRect = (rect, opts) ->
    o = rect.origin() # get origin vector
    @ctxt.beginPath();
    @ctxt.rect(o.e(1), o.e(2), rect.width, rect.height)
    @ctxt.closePath()
    @ctxt.stroke()
    
  # rotate the canvas
  # @params {Float} rot radians
  rotate = (rot) ->
    @ctxt.rotate rot
    
  # translate the canvas to a position
  # @param {Float} x
  # @param {Float} y
  translate = (x, y) ->
    @ctxt.translate x, y
    
  # Clear the canvas
  # @param {Object} opts
  clear = (opts={}) ->
    @ctxt.fillStyle = opts.color || "rgb(255,255,255)"
    @ctxt.fillRect 0, 0, @width, @height
   
  # Perform actions in a canvas context
  inContext = (fn) ->
    @ctxt.save()
    fn(@ctxt) # pass context back to callback as argument
    @ctxt.restore()
    
  # return the constructor
  Constr.prototype = {
    constructor: Canvas
    version: "1.0"
    setOrigin: setOrigin
    drawCircle: drawCircle
    drawCircleAt: drawCircleAt
    drawLine: drawLine
    drawEllipse: drawEllipse
    drawRect: drawRect
    inContext: inContext
    inWorldView: inWorldView
    context: context
    rotate: rotate
    translate: translate
    clear: clear
  }
  Constr
)()

root = exports ? window
root.Canvas = Canvas
