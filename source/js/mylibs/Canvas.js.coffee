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
  
  # Set the origin of the canvas
  # @param {String} id (topleft | bottomleft)
  setOrigin = (id) ->
    if id == 'topleft'
      # translate world for origin at bottom left
      @ctxt.scale(1, -1)
      @ctxt.translate(0, -@height)
  
  # Draw a circle on the canvas
  # @param {Circle} c a Circle object
  drawCircle = (c) ->
    @ctxt.fillStyle = c.color if c.color?
    @ctxt.beginPath()
    @ctxt.arc(c.x(), c.y(), c.radius, 0, Math.PI*2, true);
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
    fn()
    @ctxt.restore()
    
  # return the constructor
  Constr.prototype = {
    constructor: Canvas
    version: "1.0"
    setOrigin: setOrigin
    drawCircle: drawCircle
    drawLine: drawLine
    drawEllipse: drawEllipse
    inContext: inContext
    rotate: rotate
    translate: translate
    clear: clear
  }
  Constr
)()

root = exports ? window
root.Canvas = Canvas
