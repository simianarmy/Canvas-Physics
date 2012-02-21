# rot_collisisons.js
# 
# main() for the rotation collisions page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Math
#= require mylibs/Array
#= require mylibs/Line
#= require mylibs/Circle
#= require mylibs/Rectangle
#= require mylibs/Canvas
#= require mylibs/collisions

$(document).ready ->
  canvas = new Canvas($("#maincanvas").get(0))
  canvas.setOrigin('bottomleft')
  elapsed = lastTime = 0
  
  line = line2 = null
  ball = null
  rec = null
  objects = []
  otherObject = 0
  paused = true
  ballMoving = false
  rotationOffset = false
  lineLength = 0
  angle = 0
  startingAngle  = 0
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
    angle = lastAngle = startingAngle = $("input[name=sAngle]").val() || 0
    angularVel = $("input[name=angVel]").val() || 0
    otherObject = parseInt($("input[name=object]:checked").val())
    rotationOffset = $("input[name=rotationOffset]:checked").val() == "1"
    $('#sangle').html(startingAngle)
    $('#angvel').html(angularVel)
    objects = []
    ball = null
    line2 = null
    lineLength = 150
    
    # draw rotating line
    line = new Line(canvas.width/2, canvas.height/2, 0, 0, {
      color: 'black',
      rotation: startingAngle,
      length: lineLength
    })
    objects.push line
    
    # Create other object based on selection
    switch otherObject
      when 1, 2
        # other object is ball
        ball = new Circle(canvas.width/2+lineLength/1.2, canvas.height/2, 0, {
          radius: lineLength/8,
          color: 'blue'
        })
        # give ball a velocity if moving option checked
        if otherObject == 2
          ballMoving = true
          ball.velocity = $V([-5, 10, 0])
        # these two variable can be computed dynamically if the ball is moving
        ballDistance = ball.pos.subtract(line.pos).mag()
        ballAngle = Math.degreesToRadians 90
        objects.push ball
      when 3, 4
        # other object is line.  need vector for direction, not rotation
        line2Angle = $("input[name=s2Angle]").val() || 350
        line2Length = 250
        
        line2 = new Line(line.x()+145, line.y()-50, 0, 0, {
          rotation: line2Angle,
          length: line2Length
        })
        if otherObject == 4
          line2.setAngularVelocity(-angularVel)
          
        objects.push line2
    
    rec = new Rectangle(canvas.width/2, canvas.height/2, 0, 40, 40, {
      rotation: startingAngle
    })
    
    # make line fixed to rectangle side if rotation offset checked
    if rotationOffset
      line.moveTo(if canvas.inWorldView() then rec.origin() else rec.cartesianOrigin())
      # point of rotation's perp. distance from line
      perpDist = rec.height / 2
      
    line.setAngularVelocity(angularVel)
    angVel = line.angularVelocity('r')
    lineToCenterDist = line.pos.subtract(rec.pos).mag()
    
    clearInfo()
    drawInfo("Angle: #{line.rotation}")
    drawInfo("Line length: #{lineLength}")
    drawInfo("rotation axis: #{line.pos.inspect()}")
    drawInfo("ang vel: #{angVel}")
    drawInfo("k: #{perpDist}")
    drawInfo("d to center: #{lineToCenterDist}")
    
  updateObjects = (t) ->
    # update the line's rotation and others
    line.moveByTime(t)
    rec.rotation = line.rotation
    ball.moveByTime(t) if ball
    line2.moveByTime(t) if line2
    
    # if rotating around a point
    if rotationOffset
      # get new origin of rotated rectangle and move line to it
      o = rec.cartesianOrigin()
      # Use negative rotation to force clockwise rotation direction
      o2 = o.to2D().rotate(Math.degreesToRadians(-rec.rotation), rec.pos.to2D())      
      line.moveTo $V([o2.e(1), o2.e(2), 0])
    
  checkCollisions = (t) ->
    # Pick earliest time to collision from list
    firstCollision = (times...) ->
      (t for t in times when collisions.isImpendingCollision(t)).min()
    
    # Use different detection methods depending on ball movement
    if ballMoving
      res = collisions.angularCollisionLineCircle2(line, ball, t)
      collisionIn = res.t
      paused = collisionIn == 0
    else if ball
      collisionIn = collisions.angularCollisionLineCircle(
        Math.degreesToRadians(line.rotation), 
        angVel, line.length, 
        ball.radius, ballDistance, ballAngle, 
        perpDist)
    else # another line
      if line2.isRotating()
        # check using triangle test
        res = collisions.angularCollisionLineLine(line, line2, t)
        collisionIn = res.t
        paused = collisionIn == 0
      else # colliding with stationary line
        # check for collision on flat
        c1 = collisions.angularCollisionLineStationaryLine(
          Math.degreesToRadians(line.rotation),
          angVel, 
          line, line2, false)
        # check for collision with endpoints
        c2 = collisions.angularCollisionLineStationaryLine(
            Math.degreesToRadians(line.rotation),
            angVel, 
            line, line2, true)
        collisionIn = firstCollision(c1, c2) || collisions.NONE
      
    paused ||= collisions.isImpendingCollision(collisionIn) && (Math.abs(collisionIn) < 0.04)
  
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
  
