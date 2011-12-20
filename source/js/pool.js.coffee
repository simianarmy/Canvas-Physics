# pool.js.coffee

#= require ./mylibs/PoolTable
#= require ./mylibs/canvasEvents

$(document).ready ->
  shooting = false
  
  # fetch and save the canvas context
  canvas = $("#poolcanvas").get(0)
  context = canvas.getContext('2d')  
    
  sc = PoolTable(context, {
    width: canvas.width
    height: canvas.height
    tableSize: 300
  })
  cevents = canvasEvents(canvas)

  mouseMove = (evt) ->
    pnt = cevents.mouseMove(evt)
    sc.updateCue(pnt) unless shooting
      
  mouseDown = (evt) ->
    pnt = cevents.mouseDown(evt)
    shooting = true

  mouseUp = (evt) ->
    shooting = false
    
  canvas.addEventListener('mousedown', mouseDown, false)
  canvas.addEventListener('mouseup', mouseUp, false)
  canvas.addEventListener('mousemove', mouseMove, false)
