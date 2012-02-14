# rot_collisisons.js
# 
# main() for the rotation collisions page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Math
#= require mylibs/Line
#= require mylibs/Circle
#= require mylibs/Rectangle
#= require mylibs/Canvas
#= require mylibs/collisions

$(document).ready ->
  canvas = new Canvas($("#maincanvas").get(0))
  canvas.setOrigin('bottomleft')
  elapsed = lastTime = startingAngle = startingTheta = 0
  
  angle = 0
  lineLength = 200
  line = null
  ball = null
  rec = null
  objects = []
  paused = true
  ballMoving = false
  rotationOffset = false
  angVel = ballDistance = ballAngle = perpDist = collisionIn = 0
    
  drawInfo = (text) ->
    $('#info').append(text + '<br/>')
    
  clearInfo = ->
    $('#info').html('')
    
  drawText = (text, x, y) ->
    canvas.inContext((ctxt) ->
      # when origin is cartesian, we must restore to world view to draw text
      if !canvas.inWorldView()
        ctxt.scale(1, -1);
        ctxt.translate(0, -canvas.height);
      ctxt.fillStyle    = 'black'
      ctxt.font         = '12px Arial sans-serif'
      ctxt.textBaseline = 'top'
      ctxt.fillText(text, x, y)
    )
    
  drawScene = () ->
    canvas.clear()
    
    drawText "Collision in #{collisionIn}", canvas.width/2, 20
    drawText "angle: #{line.rotation}", canvas.width/2, 40
    
    for obj in objects
      switch obj.name
        when 'Line'
          canvas.drawCircleAt(obj.x(), obj.y(), 1, {color: 'black'})
          canvas.inContext ->
            if obj.rotation != 0
              canvas.translate obj.x(), obj.y()
              canvas.rotate(Math.degreesToRadians(obj.rotation))
              canvas.translate(-obj.x(), -obj.y())
              canvas.drawLine(obj)

        when 'Circle'
          canvas.inContext ->
            canvas.drawCircle obj
        
        when 'Rectangle'
          canvas.inContext((ctxt) ->
            # Draw center of rectangle
            canvas.drawCircleAt(obj.x(), obj.y(), 2, {color: 'black'})
            
            if obj.rotation != 0
              canvas.translate obj.x(), obj.y()
              canvas.rotate(Math.degreesToRadians(obj.rotation))
              canvas.translate(-obj.x(), -obj.y())
            canvas.drawRect obj
            )
  
  setupScene = ->
    startingAngle = $("input[name=sAngle]").val() || 0
    angularVel = $("input[name=angVel]").val() || 0
    ballMoving = $("input[name=movingBall]:checked").val() == "1"
    rotationOffset = $("input[name=rotationOffset]:checked").val() == "1"
    $('#sangle').html(startingAngle)
    $('#angvel').html(angularVel)
    startingTheta = 90 - startingAngle
    
    # draw rotating line
    angle = lastAngle = startingAngle
    line = new Line(canvas.width/2, canvas.height/2, lineLength, 0, {
      color: 'black',
      rotation: startingAngle,
      length: lineLength
    })
    # draw stationary circle
    ball = new Circle(canvas.width/2+lineLength/1.2, canvas.height/2, 0, {
      radius: lineLength/8,
      color: 'blue'
    })
    rec = new Rectangle(canvas.width/2, canvas.height/2, 0, 40, 40, {
      rotation: startingAngle
    })
    # give ball a velocity if moving option checked
    if ballMoving
      ball.velocity = $V([-5, 10, 0])
      
    # make line fixed to rectangle side if rotation offset checked
    if rotationOffset
      line.moveTo(if canvas.inWorldView() then rec.origin() else rec.cartesianOrigin())
      # point of rotation's perp. distance from line
      perpDist = rec.height / 2
      
    # these two variable can be computed dynamically if the ball is moving
    ballDistance = ball.pos.subtract(line.pos).mag()
    ballAngle = Math.degreesToRadians 90
    line.setAngularVelocity(angularVel)
    angVel = Math.degreesToRadians(line.angularVelocity())
    objects = [line, ball, rec]
    lineToCenterDist = line.pos.subtract(rec.pos).mag()
    
    clearInfo()
    drawInfo("Theta0: #{startingTheta}")
    drawInfo("Angle: #{line.rotation}")
    drawInfo("ball angle: 90")
    drawInfo("Line length: #{lineLength}")
    drawInfo("rotation axis: #{line.pos.inspect()}")
    drawInfo("ball pos: #{ball.pos.inspect()}")    
    drawInfo("axis-ball distance: #{ballDistance}")
    drawInfo("ang vel: #{angVel}")
    drawInfo("k: #{perpDist}")
    drawInfo("d to center: #{lineToCenterDist}")
    
  updateObjects = (t) ->
    # update the line's rotation
    omega = line.angularVelocity() * t
    rot = line.rotation - omega
    if Math.abs(rot) >= 360
      rot = 0
    
    ball.moveByTime(t)
    line.rotation = rot
    rec.rotation = rot
    # if rotating around a point
    if rotationOffset
      # get new origin of rotated rectangle and move line to it
      o = rec.cartesianOrigin()
      o2 = o.to2D().rotate(Math.degreesToRadians(rot), rec.pos.to2D())      
      line.moveTo $V([o2.e(1), o2.e(2), 0])
    
  checkCollisions = (t) ->
    # Use different detection methods depending on ball movement
    if ballMoving
      # BUG: False positives at omega > 16!??
      res = collisions.angularCollisionLineCircle2 line, ball, t
      collisionIn = res.t
      paused = collisionIn == 0
    else
      collisionIn = collisions.angularCollisionLineCircle(Math.degreesToRadians(90-line.rotation), 
        angVel, lineLength, ball.radius, ballDistance, ballAngle, perpDist)
      paused = collisions.isImpendingCollision(collisionIn) && (Math.abs(collisionIn) < 0.02)
    
  
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
    
    drawScene(objects, elapsed)
    
  # event handlers
  $('canvas').click ->
    paused = !paused
      
  $('input').change -> setupScene()
    
  setupScene()
  tick()
  
