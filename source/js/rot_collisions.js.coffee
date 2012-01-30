# rot_collisisons.js
# 
# main() for the rotation collisions page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Line
#= require mylibs/Circle
#= require mylibs/Canvas

$(document).ready ->
  canvas = new Canvas($("#maincanvas").get(0))
  canvas.setOrigin('topleft')
  elapsed = lastTime = 0
  angle = 0
  angleInc = .3
  lineLength = 200
  line = null
  ball = null
  objects = []
  paused = true
  
  drawScene = (objects, dt) ->
    canvas.clear()
    
    for obj in objects
      switch obj.name
        when 'Line'
          canvas.inContext ->
            canvas.translate obj.pos.e(1), obj.pos.e(2)
            canvas.rotate(degreesToRadians(angle))
            canvas.translate(-obj.pos.e(1), -obj.pos.e(2))
            canvas.drawLine(obj)

        when 'Circle'
          canvas.inContext ->
            canvas.drawCircle obj
    
  setupScene = ->
    # draw rotating line
    angle = 90
    line = new Line(canvas.width/2, canvas.height/2, lineLength, 0, {
      color: 'black'
    })
    # draw stationary circle
    ball = new Circle(canvas.width/2+lineLength/2, canvas.height/2+40, 0, {
      radius: lineLength/8
      color: 'blue'
    })
    objects = [line, ball]
    
  # animate all objects
  update = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = timeNow - lastTime
      angle -= angleInc
      if Math.abs(angle) >= 360
        angle = 0
      
    lastTime = timeNow

  # tick funtion
  tick = ->
    requestAnimFrame(tick) 
    unless paused
      update()
      drawScene(objects, elapsed)
  
  # event handlers
  $('canvas').click ->
    paused = !paused
      
  setupScene()
  tick()
  
