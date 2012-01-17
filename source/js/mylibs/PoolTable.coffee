# PoolTable.coffee 

#= require ./vec
#= require ./collisions
#= require ./Line
#= require ./Circle

NUM_BALLS           = 16
BALL_RADIUS         = 10
POCKET_SIZE         = 1.7
JAW_SIZE            = 1.2
DECELARATION        = .9
CUSHION_EFFICIENCY  = 0.7
CUEING_SCALE        = 10
BALL_COLORS         = ['white', 'yellow', 'blue', 'red', 'purple', 'orange', '#00DD00', 'maroon',
                      'yellow', 'blue', 'red', 'purple', 'orange', '#00DD00', 'maroon', 'black']

# the pool table object
PoolTable = (ctxt, opts) ->
  context = ctxt
  # Set game params from options or defaults
  cw                = opts.width
  ch                = opts.height
  tableSize         = opts.tableSize
  ballRadius        = opts.ballRadius ? BALL_RADIUS
  pocketSize        = opts.pocketSize ? POCKET_SIZE
  jawSize           = opts.jawSize ? JAW_SIZE
  frictionDecelaration = opts.decelaration ? DECELARATION
  cushionEfficiency = opts.efficiency ? CUSHION_EFFICIENCY
  cueImg    = null
  cuePos    = null
  cueRot    = 0
  cueRotDegrees = 0
  lastCuePos = null
  cueLen = 0
  cueVec    = Vector.Zero()
  cueStartTime = 0
  cueing    = false
  balls     = []
  cushions  = []
  pockets   = []
  jaws      = []
  jawArcRadius = 0
  xoffset   = cw / 4
  yoffset   = 100
  voff      = null
  ticks = 0
  lastTime = 0
  animating = false
  
  # setup
  setup = ->
    console.log "setting up game objects"
    rs = ballRadius * pocketSize
    rd = ballRadius * Math.sqrt(2.0) * pocketSize
    
    console.log "Table size: #{tableSize}\nball radius: #{ballRadius}\npocket size: #{pocketSize}\njaw size: #{jawSize}"
    console.log "rs: #{rs}, rd: #{rd}"
    wallOpts = {mass: Infinity, efficiency: cushionEfficiency}
    
    # Make table cushions
    # Assuming the table is aligned vertically, major axis is height
    cushions = [new Line(rd, 0, tableSize-rd*2, 0, wallOpts) # top
      ,new Line(0, rd, 0, tableSize-rd-rs, wallOpts) # left top
      ,new Line(0, tableSize+rs, 0, tableSize-rd-rs, wallOpts) # left bottom
      ,new Line(rd, tableSize*2, tableSize-rd*2, 0, wallOpts) # bottom
      ,new Line(tableSize, rd, 0, tableSize-rd-rs, wallOpts) # right top
      ,new Line(tableSize, tableSize+rs, 0, tableSize-rd-rs, wallOpts) # right bottom
    ]
    # Offset cushions from canvas border so that lines draw correctly
    voff = $V([xoffset, yoffset, 0])
    for wall in cushions
      wall.pos = wall.pos.add(voff)
    
    # pw is the radius of the circular arcs at the pocket entrances
    jawArcRadius = pw = ballRadius * jawSize
    
    createPocket = (v) ->
      new Circle(v.e(1), v.e(2), 0, {radius: jawArcRadius})
      
    createJaw = (v, orientation) ->
      p = createPocket v
      # code below is for drawing jaws as ellipses.  not currently used
      if orientation == 'v'
        p.width = pw
        p.height = pw*4
      else
        p.width = pw*4
        p.height = pw
      p
     
    # Use walls as guide to create jaws
    for wall in cushions
      if wall.vec.e(1) == 0 # this is a vertical wall
        if wall.pos.e(1) > tableSize/2 # its on the right
          jaws.push createJaw(wall.pos.add(point(pw, 0)), 'v')
          jaws.push createJaw(wall.pos.add(wall.vec).add(point(pw, 0)), 'v')
        else # its on the left
          jaws.push createJaw(wall.pos.subtract(point(pw, 0)), 'v')
          jaws.push createJaw(wall.pos.add(wall.vec).subtract(point(pw, 0)), 'v')
      else # this is a horizontal wall
        if wall.pos.e(2) > tableSize # its on the bottom
          jaws.push createJaw(wall.pos.add(point(0, pw)), 'h')
          jaws.push createJaw(wall.pos.add(wall.vec).add(point(0, pw)), 'h')
        else # its on the top
          jaws.push createJaw(wall.pos.subtract(point(0, pw)), 'h')
          jaws.push createJaw(wall.pos.add(wall.vec).subtract(point(0, pw)), 'h')
    
    # Create the pockets
    xx = voff.e(1) + tableSize
    yy = voff.e(2) * 2/3
    b = 1
    pockets = [createPocket(point(yy+b/3, yy+b/3)), 
      createPocket(point(xx, yy+b/3)),
      createPocket(point(yy, xx)),
      createPocket(point(xx+b/3, xx)),
      createPocket(point(yy+b/3, xx*2-b)),
      createPocket(point(xx, xx*2-b))
    ]
    # Make balls
    createBalls()
    
    # Make pool cue
    createCue()
    
    toggleAnimation()
    
  createBalls = ->
    r = ballRadius * 1.02 # Add space between racked balls for initial collision resolutions
    cuestart = $V([tableSize/2, 2*tableSize/5, 0]).add(voff)
    y = Math.sqrt(3.0) * r
    tristart = $V([tableSize/2, tableSize*3/2, 0]).add(voff)
     
    # Racked ball positions
    ballPosition = (i) ->
      switch i
        when 1 then cuestart
        when 2 then tristart
        when 3 then tristart.add $V([-r, y, 0])
        when 4 then tristart.add $V([r, y, 0])
        when 5 then tristart.add $V([2*r, 2*y, 0])
        when 6 then tristart.add $V([-2*r, 2*y, 0])
        when 7 then tristart.add $V([-3*r, 3*y, 0])
        when 8 then tristart.add $V([-r, 3*y, 0])
        when 9 then tristart.add $V([r, 3*y, 0])
        when 10 then tristart.add $V([3*r, 3*y, 0])
        when 11 then tristart.add $V([4*r, 4*y, 0])
        when 12 then tristart.add $V([0, 4*y, 0])
        when 13 then tristart.add $V([2*r, 4*y, 0])
        when 14 then tristart.add $V([-4*r, 4*y, 0])
        when 15 then tristart.add $V([-2*r, 4*y, 0])
        when 16 then tristart.add $V([0, 2*y, 0])
      
    for i in [1..NUM_BALLS]
      p = ballPosition(i)
      balls.push new Circle(p.e(1), p.e(2), p.e(3), {
        radius: ballRadius
        color: BALL_COLORS[i-1]        
        speed: 0
        pocketed: false
        moving: false
        number: i
        }) 
  
  createCue = ->
    cueImg = new Image
    cueImg.src = '/img/poolcue.png'
    
  # Convenience point to vector function
  point = (x, y, z=0) ->
    $V([x, y, z])
  
  point2D = (x, y) ->
    $V([x, y])
    
  drawLine = (line) ->
    endpoint = line.pos.add(line.vec)
    context.moveTo line.pos.e(1), line.pos.e(2)
    context.lineTo endpoint.e(1), endpoint.e(2)
    context.stroke()
    
  
  drawEllipse = (c, width, height) ->
    centerX = c.x()
    centerY = c.y()
    context.beginPath();
    context.moveTo(centerX, centerY - height/2) # A1
    context.bezierCurveTo(
      centerX + width/2, centerY - height/2, # C1
      centerX + width/2, centerY + height/2, # C2
      centerX, centerY + height/2) # A2

    context.bezierCurveTo(
      centerX - width/2, centerY + height/2, # C3
      centerX - width/2, centerY - height/2, # C4
      centerX, centerY - height/2) # A1

    context.stroke()
    context.closePath();

  drawJaw = (j) ->
    # scale for ellipse?
    #context.scale(0.75, 1)
    context.beginPath()
    context.arc(j.x(), j.y(), j.radius, 0, Math.PI*4, false)
    #drawEllipse(j, j.width, j.height)
    context.stroke()
    context.closePath()
    
  drawTable = ->
    # Draw the cushions
    context.save()
    context.strokeStyle = 'black'
    for wall in cushions
      drawLine(wall)
    context.restore()
    
    context.fillStyle = "#00aa00"
    context.fillRect(voff.e(1), voff.e(2), tableSize, tableSize * 2)
    
    # Draw the pocket corners
    pt = $V([jawArcRadius, jawArcRadius, 0])
    context.save()
    context.strokeStyle = 'grey'
    for j in jaws
      drawJaw(j)

    #pt = point(ballRadius * pocketSize, ballRadius * pocketSize)
    for p in pockets
      context.beginPath()
      context.arc(p.x(), p.y(), jawArcRadius, 0, Math.PI*2, false)
      context.stroke()
      context.closePath()
      
  drawBalls = ->
    for ball in balls
      context.fillStyle = ball.color
      context.beginPath()
      context.arc(ball.x(), ball.y(), ball.radius, 0, Math.PI*2, true);
      context.closePath();
      context.fill();

  drawCue = ->
    # Wait until cue image fully loaded
    return unless lastCuePos? and cueImg.width > 0 and cueImg.height > 0
    # Cue start point relative to ball
    ogCuePos = point(-(cueImg.width-ballRadius/1.5), -(cueImg.height+ballRadius/2))
        
    #context.fillText "cue angle: #{cueRotDegrees}", 0, 20
    if cueing
      # Get offset vector for drawing cue back
      elapsed = new Date().getTime() - cueStartTime
      yoff = (elapsed / 1000) * 40
      ogCuePos = ogCuePos.add(point(0, -yoff))
      
    context.save()
    context.translate balls[0].pos.e(1), balls[0].pos.e(2)
    context.rotate degreesToRadians(cueRotDegrees)
    context.translate ogCuePos.e(1), ogCuePos.e(2)
    context.drawImage(cueImg, 0, 0, cueImg.width, cueImg.height)
    context.restore()
    
    # if lastCuePos?
    #       cuev = balls[0].pos.subtract(lastCuePos).x(10)
    #       # draw guide line
    #       context.save()
    #       drawLine(new Line(balls[0].pos.e(1), balls[0].pos.e(2), cuev.e(1), cuev.e(2)))
    #       context.restore()
  
  cueAngle = (cuePos) ->
    v = balls[0].pos.subtract(cuePos)
    if v.mag() > 0
      # Adjust angle for vertical cue alignment
      (Math.atan2(v.e(2), v.e(1)) * 180 / Math.PI) - 90
  
  displacement = (ts, vel) ->
    unless vel?
      foo = 0
      throw "wtf?" 
    vel.x(ts / 1000.0)
        
  # Moves some shape for some timestep
  #
  # @param {Shape} s - object to move
  # @param {Number} ts - timestep
  moveObject = (s, ts) ->
    disp = displacement(ts, s.velocity)
    #console.log "Moving #{s.number} by #{disp.inspect()}"
    s.move disp
  
  ballIsMoving = (b) ->
    b.speed > Sylvester.precision
    
  ballsMoving = ->
    for b in balls
      return true if ballIsMoving(b)
    false      

  applyFrictionToBalls = (balls) ->
    for b in balls when b.moving
      # slow ball speed from friction
      b.speed = Math.max(b.speed - frictionDecelaration, 0)
      # Adjust moving flag in case ball has stopped
      b.moving = ballIsMoving(b)
  
  # Pool game specific collision detection
  # @param {Number} timestep since last call  
  # @param {Array} moving objects  
  # @param {Array} fixed objects  
  moveBalls = (ts, balls, cushions, pockets) ->
    applyFrictionToBalls(balls)
    
    return "stopped" unless ballsMoving()
    ogts = ts
    
    while ts > Sylvester.precision
      mn = 2
      ob1 = ob2 = null
      n = Vector.Zero(3)
      collisionNormal = null
      collisionTime = 0
      tp = null

      detectCollisionHelper = (s1, s2, objType) ->
        s1.velocity = s1.direction.x(s1.speed)
        s2.velocity = s2.direction.x(s2.speed)
        s1.displacement = displacement(ts, s1.velocity)
        s2.displacement = displacement(ts, s2.velocity)

        [collisionTime, collisionNormal] = collisions.detectCollision s1, s2
          
        return unless collisions.isImpendingCollision(collisionTime)
        console.log "#{objType} collision in #{collisionTime}!"

        m = Math.min(mn, collisionTime)
        # If collision is most imminent, save objects' info
        if m < mn
          mn = m
          n = collisionNormal.dup()
          ob1 = s1
          ob2 = s2
          s1.collided = s2.collided = true
          tp = objType
          
      for i in [0...balls.length]
        b1 = balls[i]

        # check for collisions between balls
        for j in [(i+1)...balls.length]
          b2 = balls[j]
          if b1.moving || b2.moving
            #console.log "detecting collision b/w balls #{b1.number}, #{b2.number}"
            detectCollisionHelper b1, b2, "ball"
            
        # check for collisions with cushions    
        if b1.moving
          for w in cushions
            #console.log "detecting collision b/w ball #{b1.number} and cushion"
            detectCollisionHelper b1, w, "wall"
        
          # check for ball pocketing
          #for p in pockets
            #console.log "detecting collision b/w ball #{b1.number} and pocket"
            #detectCollisionHelper b1, p, "wall"
      
      # if there is no collision we are finished
      break if mn == 2
      
      # there is a collision
      # move balls to collision position
      if mn > Sylvester.precision
        for b in balls when b.moving
          moveObject(b, mn*ts)

      # resolve collisions
      if tp == "wall"
        collisions.resolveInelasticCollisionFixed(ob1, ob2, n)
        ob1.speed = ob1.velocity.mag()
        ob1.direction = ob1.velocity.toUnitVector()
      else
        console.log "resolving collision b/w #{ob1.number} & #{ob2.number}"
        collisions.resolveCollision ob1, ob2, n
        ob1.speed = ob1.velocity.mag()
        ob2.speed = ob2.velocity.mag()
        if ob1.moving = ballIsMoving(ob1)
          #console.log "ball #{ob1.number} speed: #{ob1.speed} velocity: #{ob1.velocity.inspect()}"
          ob1.direction = ob1.velocity.toUnitVector()
        if ob2.moving = ballIsMoving(ob2)
          #console.log "ball #{ob2.number} speed: #{ob2.speed} velocity: #{ob2.velocity.inspect()}"
          ob2.direction = ob2.velocity.toUnitVector()
          
      # decrease time and repeat
      ts *= (1 - mn)
    # End while ts > 0
    
    # move balls for the last section (no collisions)
    for b in balls when b.moving
      moveObject(b, ts)
    
  # toggle the animation on and off
  toggleAnimation = ->
    animating = !animating
    lastTime = 0
    tick()

  # draw all objects on the canvas
  drawScene = ->
    context.clearRect 0, 0, cw, ch
    # Draw table
    drawTable()
    drawBalls()
    drawCue() unless ballsMoving()
    
  # animate all objects
  animate = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = timeNow - lastTime
      moveBalls(elapsed, balls, cushions, pockets)
        
    lastTime = timeNow

  # tick funtion
  tick = ->
    requestAnimFrame(tick) 
    drawScene()
    animate()
    ticks += 1

  # Initialize
  setup()
  
  # Public functions
  
  updateCue = (mousePos) ->
    cueRotDegrees = cueAngle(point(mousePos.x, mousePos.y))
    lastCuePos = point(mousePos.x, mousePos.y)
  
  # Making the shot
  initShot = ->
    console.log "Starting shot..."
    # Freeze cue direction vector
    cueVec = balls[0].pos.subtract(lastCuePos).toUnitVector()
    cueStartTime = new Date().getTime()
    cueing = true
    
  # Shoot!
  makeShot = (cueSpeed) ->
    console.log "Shooting with speed: #{cueSpeed} and dir #{cueVec.inspect()}"
    cueing = false
    balls[0].direction = cueVec.dup()
    balls[0].speed = cueSpeed
    balls[0].moving = true
    
  # Return public functions
  {updateCue, initShot, makeShot}

root = exports ? window
root.PoolTable = PoolTable

