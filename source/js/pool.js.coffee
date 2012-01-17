# pool.js.coffee

#= require ./mylibs/PoolTable
#= require ./mylibs/canvasEvents

MAX_CUE_TIME        = 2
MAX_BALL_SPEED      = 130

$(document).ready ->
  shooting = false
  shotForce = 0
  shotTimerID = null
  cueStart = 0
  
  # fetch and save the canvas context
  canvas = $("#poolcanvas").get(0)
  context = canvas.getContext('2d')  
    
  sc = PoolTable(context, {
    width: canvas.width
    height: canvas.height
    tableSize: 300
  })
  cevents = canvasEvents(canvas)

  incShotForce = ->
    shotForce += 1
    timeNow = new Date().getTime()
    elapsed = 0
    if cueStart != 0
      elapsed = timeNow - cueStart
    
    shoot() if elapsed/1000 >= MAX_CUE_TIME
  
  shoot = ->
    cueSpeed = (shotForce / MAX_CUE_TIME) * MAX_BALL_SPEED
    sc.makeShot cueSpeed
    endShot()
    
  startShot = ->
    shotForce = 0
    cueStart = new Date().getTime()
    shotTimerID = setInterval(incShotForce, 200)
    shooting = true
    
  endShot = ->
    shooting = false
    clearInterval shotTimerID
    shotForce = 0
    
  mouseMove = (evt) ->
    pnt = cevents.mouseMove(evt)
    sc.updateCue(pnt) unless shooting
      
  mouseDown = (evt) ->
    pnt = cevents.mouseDown(evt)
    unless shooting
      sc.initShot pnt
      startShot()

  mouseUp = (evt) ->
    shoot() if shooting
    shooting = false
    
  canvas.addEventListener('mousedown', mouseDown, false)
  canvas.addEventListener('mouseup', mouseUp, false)
  canvas.addEventListener('mousemove', mouseMove, false)
