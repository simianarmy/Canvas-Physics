# rect_collisisons.js
#
# main() for the rectangle collisions page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Math
#= require mylibs/Rectangle
#= require mylibs/Canvas
#= require mylibs/collisions

$(document).ready ->
  canvas = new Canvas($("#maincanvas").get(0))
  canvas.setOrigin('topleft')
  elapsed = lastTime = 0
  objects = r1 = r2 = null
  paused = true
  axisAligned = true
  rot = 0
  rev = 'v5'

  drawText = (text, x, y) ->
    canvas.drawText text, x, y

  drawScene = () ->
    canvas.clear()
    i = 1
    drawText rev, 10, 10
    for r in objects
      canvas.drawRect(r)
      drawText(r.pos.inspect() + ' ' + r.radRotation() + ' rads', 10, 10 + (i++ * 20))
      for r in r.vertices()
        drawText($V([r.e(1).toFixed(2), r.e(2).toFixed(2)]).inspect(), r.e(1), r.e(2))

    true
    
  setupScene = ->
    axisAligned = ($("input[name=axisaligned]:checked").length > 0)
    r1 = new Rectangle($V([canvas.width/2 - 140, canvas.height/2]), $V([80, 0, 0]), $V([0, 30, 0]))
    r2 = new Rectangle($V([canvas.width/2 + 100, canvas.height/3]), $V([50, 0, 0]), $V([0, 100, 0]))
    r1.name = 'rect 1'
    r2.name = 'rect 2'
    r1.color = "rgb(200, 0, 0)"
    r2.color = "#00FF00"
    r1.setVelocity $V([40, -10, 0])
    r2.setVelocity $V([-20, 0, 0])
    if !axisAligned
        r1.setRotation 20
        r2.setRotation 60
    objects = [r1, r2]

  updateObjects = (t) ->
    # update the line's rotation and others
    for r in objects
      r.moveByTime(t)
      
  checkCollisions = (t) ->
    res = if axisAligned
      collisions.rectangleRectangleCollisionStraight(r1, r2, t)
    else
      collisions.rectangleRectangleCollisionAngled(r1, r2, t)
    
    if (res != collisions.NONE) && collisions.isImpendingCollision(Math.abs(res))
      console.log('*** collision in ' + res)
      paused = true
    
    #debugger if r2.origin().e(1) <= (r1.origin().e(1) + r1.width - 20)
    
  # animate all objects
  update = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = (timeNow - lastTime) / 1000
      elapsed = 0.1 if elapsed > 0.1
      updateObjects(elapsed)
      checkCollisions(elapsed)

    lastTime = timeNow

  # tick funtion
  tick = ->
    requestAnimFrame(tick)
    unless paused
      update()

    drawScene(elapsed)

  # event handlers
  $('canvas').click ->
    paused = !paused

  $('input').change -> setupScene()

  setupScene()
  tick()
