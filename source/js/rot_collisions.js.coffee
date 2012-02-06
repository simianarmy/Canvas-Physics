# rot_collisisons.js
# 
# main() for the rotation collisions page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Math
#= require mylibs/Line
#= require mylibs/Circle
#= require mylibs/Canvas
#= require mylibs/collisions

$(document).ready ->
  canvas = new Canvas($("#maincanvas").get(0))
  #canvas.setOrigin('topleft')
  elapsed = lastTime = startingAngle = startingTheta = 0
  
  angle = 0
  lineLength = 200
  line = null
  ball = null
  objects = []
  paused = true
  angVel = ballDistance = ballAngle = collisionIn = 0
    
  drawInfo = (text) ->
    $('#info').append(text + '<br/>')
    
  clearInfo = ->
    $('#info').html('')
    
  drawText = (text) ->
    canvas.inContext ->
      ctxt = canvas.context()
      ctxt.fillStyle    = 'black'
      ctxt.font         = '12px Arial sans-serif'
      ctxt.textBaseline = 'top'
      ctxt.fillText(text, canvas.width/2, 10)
    
  drawScene = () ->
    canvas.clear()
    
    if collisions.isImpendingCollision(collisionIn)
      drawText "Collision in #{collisionIn}"
    else
      drawText "Collision time > 1"
    
    for obj in objects
      switch obj.name
        when 'Line'
          canvas.inContext ->
            canvas.translate obj.pos.e(1), obj.pos.e(2)
            canvas.rotate(Math.degreesToRadians(-obj.rotation))
            canvas.translate(-obj.pos.e(1), -obj.pos.e(2))
            canvas.drawLine(obj)

        when 'Circle'
          canvas.inContext ->
            canvas.drawCircle obj
    
  setupScene = ->
    startingAngle = $("input[name=sAngle]").val() || 20
    angularVel = $("input[name=angVel]").val() || 15
    startingTheta = 90 - startingAngle
    
    # draw rotating line
    angle = lastAngle = startingAngle
    line = new Line(canvas.width/2, canvas.height/2, lineLength, 0, {
      color: 'black',
      rotation: startingAngle
    })
    # draw stationary circle
    ball = new Circle(canvas.width/2+lineLength/1.2, canvas.height/2, 0, {
      radius: lineLength/8,
      color: 'blue'
    })
    
    # these two variable can be computed dynamically if the ball is moving
    ballDistance = ball.pos.subtract(line.pos).mag()
    ballAngle = Math.degreesToRadians 90
    line.setAngularVelocity(angularVel)
    angVel = Math.degreesToRadians(line.angularVelocity())
    objects = [line, ball]
    
    clearInfo()
    drawInfo("Theta0: #{startingTheta}")
    drawInfo("Line length: #{lineLength}")
    drawInfo("rotation axis: #{line.pos.inspect()}")
    drawInfo("ball pos: #{ball.pos.inspect()}")
    drawInfo("ball radius: #{ball.radius}")
    drawInfo("ball angle: #{ballAngle}")
    drawInfo("axis-ball distance: #{ballDistance}")
    drawInfo("ang vel: #{angVel}")
    
  updateObjects = (t) ->
    # update the line's rotation
    rot = line.rotation - line.angularVelocity() * (t / 1000)
    if Math.abs(rot) >= 360
      rot = 0
    line.rotation = rot
    
  checkCollisions = (t) ->
    collisionIn = collisions.angularCollisionLineCircle(Math.degreesToRadians(90-line.rotation), 
      angVel, lineLength, ball.radius, ballDistance, ballAngle)
    
  # animate all objects
  update = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = timeNow - lastTime
      updateObjects(elapsed)
      checkCollisions()
      
    lastTime = timeNow

  # tick funtion
  tick = ->
    requestAnimFrame(tick) 
    unless paused
      update()
    
    drawScene(objects, elapsed)
  
  # event handlers
  $('canvas').click ->
    checkCollisions elapsed
    paused = !paused
      
  $('input#update').click ->
    setupScene()
    
  setupScene()
  tick()
  
