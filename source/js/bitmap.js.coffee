# @module bitmapDemo

#= require ./mylibs/Math
#= require ./mylibs/Polygon
#= require ./mylibs/collisions

# @param {Image} bitmap
bitmapDemo = (bitmap) ->
  # fetch and save the canvas context
  FLIP_Y_AXIS = false
  canvas = $("#maincanvas").get(0)
  context = canvas.getContext('2d')
  # the hidden canvas for alpha testing
  hcanvas = $('#hiddencanvas').get(0)
  hcontext = hcanvas.getContext('2d')
  # save canvas dimensions and bitmap
  cw = canvas.width
  ch = canvas.height
  img = bitmap
  imgX = imgY = 0
  lastRot = 0
  shapePolygons = []
  imgPixels = imgBorderMap = null
  dragging = false
  # translate world for cartesian coordinates if desired
  if FLIP_Y_AXIS
    context.scale(1, -1)
    context.translate(0, -ch)
    
  # display canvas dimensions
  $('#info').html("Canvas: #{cw} x #{ch}<br/>")
  
  describe = (text...) ->
    txt = ''
    for t in text
      txt += '<li>' + t + '</li>' 
    $('#drawingCommands').html txt
    
  say = (text) ->
    drawText text
    
  # clear the canvas and draw the bitmap
  drawScene = ->
    imgX = cw/2 - img.width/2
    imgY = ch/2 - img.height/2
    context.clearRect(0, 0, cw, ch)
    context.drawImage(img, imgX, imgY)
    describe "clearRect(0, 0, #{cw}, #{ch})", "drawImage(img, #{imgX}, #{imgY})"
  
  # clear the canvas and draw the bitmap at some point
  drawAt = (pt) ->
    imgX = pt.x - img.width/2
    imgY = pt.y - img.height/2
    context.clearRect(0, 0, cw, ch)
    context.drawImage(img, imgX, imgY)
    imgPixels = null
    
  # display some text
  drawText = (text) ->
    tx = cw/2 + 100
    ty = ch/2
    context.clearRect(tx, ty, 100, 50)
    context.fillStyle    = '#00f'
    context.font         = '30px Arial sans-serif'
    context.textBaseline = 'top'
    context.fillText text, tx, ty
  
  # scale & draw the bitmap
  scale = (x=0.5, y=0.5) ->
    context.save()
    context.translate(imgX, imgY)
    context.scale x, y
    context.drawImage(img, imgX, imgY)
    context.restore()
    
  # rotate and draw the bitmap
  rotate = ->
    lastRot += 45
    context.save()
    context.translate(imgX, imgY)
    context.rotate Math.degreesToRadians(lastRot)
    context.drawImage(img, 0, 0)
    context.restore()

  # scale, rotate, and draw the bitmap
  scaleRotate = ->
    lastRot += 45
    context.save()
    context.translate(imgX, imgY)
    context.scale 0.5, 0.5
    context.rotate Math.degreesToRadians(lastRot)
    context.drawImage(img, 0, 0)
    context.restore()
    
  # draw image border rectangle
  drawBorder = ->
    context.save()
    context.strokeStyle = 'black';
    context.lineWidth = 3;
    context.strokeRect(imgX, imgY, img.width, img.height)
    context.restore()
    
  # Constructs bitmap shape from PhysicsEditor vertices in JSON format
  # @returns {Array} of Polygon objects
  shapePolygons = ->
    return shapePolygons if shapePolygons.length > 0
      
    shapePoints = (vertices) ->
      $V([vertices[2*i], vertices[2*i+1], 0]) for i in [0...vertices.length/2]

    new Polygon(shapePoints(vtx.shape)) for vtx in bitmapVertices.Master_Shake
  
  # fill the bitmap using PhysicsEditor vertices    
  fillShape = (fill) ->
    imgOffx = (x) -> imgX + x
    imgOffy = (y) -> imgY + y
    
    drawPoly = (vertices) ->
      v1 = vertices[0]
      context.beginPath()
      context.moveTo(imgOffx(v1.e(1)), imgOffy(v1.e(2)))
      
      for i in [1...vertices.length]
        context.lineTo(imgOffx(vertices[i].e(1)), imgOffy(vertices[i].e(2)))
      if fill then context.fill() else context.stroke()
      context.closePath()
      
    context.save()
    context.strokeStyle = 'red';
    context.lineWidth = 1;
    drawPoly(p.points) for p in shapePolygons()
    context.restore()
  
  # Returns bitmap pixel array using hidden context
  imagePixels = ->
    hcontext.clearRect(0, 0, cw, ch)
    hcontext.drawImage(img, imgX, imgY)
    hcontext.getImageData(0, 0, cw, ch).data
    
  # create the image border index map
  makeImageBorderMap = ->
    imgPixels ?= imagePixels()
    imgBorderMap = []
    outside = true
    
    alphaCheck = (i) ->
      # if alpha is not 100%, it's an image pixel
      if imgPixels[i + 3] > 0
        # outside to inside detection
        if outside
          outside = false
          imgBorderMap.push(i)
      else if !outside # inside to outside detection
        outside = true
        imgBorderMap.push(i)

    # horizontal pass
    for y in [0...cw]
      for x in [0...ch]
        idx = ((cw * y) + x) * 4
        alphaCheck idx
    
    # vertical pass
    outside = true
    for x in [0...cw]
      for y in [0...ch]
        idx = ((cw * y) + x) * 4
        alphaCheck idx
        
    imgBorderMap
    
  # attempt shape border effect on bitmap
  glow = ->
    imgBorderMap ?= makeImageBorderMap()
    imgd = context.getImageData(0, 0, cw, ch)
    pix = imgd.data

    applyBorder = (idx) ->
      #idx -= 15*4
      pix[idx ] = 255 # red
      pix[idx+1] = 0
      pix[idx+2] = 0
      pix[idx+3] = 255
      
    # Loop over border pixels and make them red
    for idx in imgBorderMap
      applyBorder idx
    
    context.putImageData(imgd, 0, 0)
    
  # invert the bitmaps non-alpha pixel colors
  invertColor = ->
    # Create an ImageData object.
    imgd = context.getImageData(imgX, imgY, img.width, img.height)
    pix = imgd.data

    # Loop over each pixel and invert the color
    for idx in [0...pix.length]
      i = idx * 4
      pix[i  ] = 255 - pix[i  ]; # red
      pix[i+1] = 255 - pix[i+1]; # green
      pix[i+2] = 255 - pix[i+2]; # blue
    
    # Draw the ImageData object at the given (x,y) coordinates.
    context.putImageData(imgd, imgX, imgY)
    
  # hit testing with polygons
  hitTestPoly = (pt) ->  
    pnt = $V([pt.x-imgX, pt.y-imgY, 0])
    # Use vertices to test for point-in-polygon
    for poly in shapePolygons()
      return true if collisions.pointInPolygon pnt, poly
    
  # hit testing with pixel alphas
  hitTestAlpha = (pt) ->
    # use the hidden canvas context to store the bitmap pixels
    imgPixels ?= imagePixels()
    idx = 4 * (pt.x + pt.y * cw) + 3;
    imgPixels[idx] > 0
  
  testHit = (pt) ->
    # use selected hit testing stragegy
    test = if $('input[name=hittest]:checked').val() == "1" then hitTestAlpha else hitTestPoly
    if test.call(this, pt) 
      say "hit!"
      true
    else
      say ""
      false
  
  # redirect to display canvas as PNG
  toPNG = ->
    window.location = canvas.toDataURL 'image/png'
  
  # mouse coordinates to canvas coordinates
  convertEventToCanvas = (evt) ->
    # get canvas position
    obj = canvas;
    top = left = 0

    while obj.tagName != 'BODY'
      top += obj.offsetTop
      left += obj.offsetLeft
      obj = obj.offsetParent

    # return relative mouse position
    mouseX = evt.clientX - left + window.pageXOffset
    mouseY = evt.clientY - top + window.pageYOffset
    p = {
      x: mouseX
      y: mouseY
    }
    p.y = ch - p.y if FLIP_Y_AXIS
    p

  # mouse event handlers
  mouseDown = (evt) ->
    cp = convertEventToCanvas evt
    console.log "mouseDown #{cp.x}, #{cp.y}"
    dragging = testHit cp
    
  mouseUp = (evt) ->
    dragging = false
    
  mouseMoved = (evt) ->
    cp = convertEventToCanvas evt
    if dragging
      drawAt cp
    else
      testHit cp
      
  canvas.addEventListener('mousedown', mouseDown, false)
  canvas.addEventListener('mouseup', mouseUp, false)
  canvas.addEventListener('mousemove', mouseMoved, false)
	
  # return public functions
  {drawScene, 
  scale, 
  rotate, 
  scaleRotate, 
  drawBorder, 
  fillShape, 
  glow, 
  invertColor, 
  drawText, 
  toPNG}
  
# main()
$(document).ready ->
  demo = null
  # Create image object from url
  mshake = new Image()
  mshake.onload = ->
    demo = bitmapDemo(this)
    demo.drawScene()
    
  mshake.src = 'img/Master_Shake.png'
  
  $('#reset').click -> demo.drawScene()
  $('#scale').click -> demo.scale()
  $('#rotate').click -> demo.rotate()
  $('#scaleRotate').click -> demo.scaleRotate()
  $('#border').click -> demo.drawBorder()
  $('#fill').click -> demo.fillShape(true)
  $('#polys').click -> demo.fillShape(false)
  $('#glow').click -> demo.glow()
  $('#invertColor').click -> demo.invertColor()
  $('input').blur -> demo.drawText($('input').val())
  $('#export').click -> demo.toPNG()
  $("#maincanvas").click -> demo.hitTest
    