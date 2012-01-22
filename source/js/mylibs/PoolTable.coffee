# PoolTable.coffee 

#= require ./vec
#= require ./collisions
#= require ./Line
#= require ./Circle

DRAW_GUIDES         = true
NUM_BALLS           = 16
BALL_RADIUS         = 10
POCKET_SIZE         = 1.8
JAW_SIZE            = 1.4
DECELARATION        = .9
CUSHION_EFFICIENCY  = 0.7
CUEING_SCALE        = 10
BALL_COLORS         = ['white', 'yellow', 'blue', 'red', 'purple', 'orange', '#00DD00', 'maroon',
                      'yellow', 'blue', 'red', 'purple', 'orange', '#00DD00', 'maroon', 'black']

Array::remove = (e) -> @[t..t] = [] if (t = @indexOf(e)) > -1

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
  onEndTurnCb       = opts.onEndTurn
  onCollisionCb     = opts.onCollision
  cueImg    = null
  cuePos    = null
  cueRot    = 0
  cueRotDegrees = 0
  lastCuePos = null
  cueLen = 0
  cueVec          = Vector.Zero(3)
  cueCenterOffset = 0
  cueStartTime = 0
  cueing    = false
  balls     = []
  cushions  = []
  jaws      = []
  
  jawArcRadius = 0
  xoffset   = cw / 4
  yoffset   = 100
  voff      = null
  ticks = 0
  lastTime = 0
  animating = false
  # turn based state vars
  shooting            = false
  pocketedOnTurn      = []
  playerColors        = {}
  currentPlayer       = null
  
  # setup
  setup = ->
    console.log "setting up game objects"
    rs = ballRadius * pocketSize
    rd = ballRadius * Math.sqrt(2.0) * pocketSize
    
    console.debug "Table size: #{tableSize}\nball radius: #{ballRadius}\npocket size: #{pocketSize}\njaw size: #{jawSize}"
    console.debug "rs: #{rs}, rd: #{rd}"
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
      new Circle(v.e(1), v.e(2), 0, {radius: ballRadius, mass: Infinity, speed: 0})
      
    createJaw = (v, orientation) ->
      p = new Circle(v.e(1), v.e(2), 0, {radius: jawArcRadius, mass: Infinity, speed: 0})
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
    sideOffset = ballRadius * 2/3
    b = 2
    jaws.push createPocket(point(xoffset-b, yoffset-b)) # left top
    jaws.push createPocket(point(xx+b, yoffset-b)) # right top
    jaws.push createPocket(point(xoffset-sideOffset, tableSize+yoffset))  #m middle left
    jaws.push createPocket(point(xx+sideOffset, tableSize+yoffset)) # middle right
    jaws.push createPocket(point(xoffset-b, yoffset+b+tableSize*2)) # left bottom
    jaws.push createPocket(point(xx+b, yoffset+b+tableSize*2)) # right bottom

    # Make balls
    createBalls()
    # Make pool cue
    createCue()
    # Turn on animation
    toggleAnimation()
    
  cuestartPos = ->
    $V([tableSize/2, 2*tableSize/5, 0]).add(voff)
    
  createBalls = ->
    r = ballRadius * 1.02 # Add space between racked balls for initial collision resolutions
    y = Math.sqrt(3.0) * r
    tristart = $V([tableSize/2, tableSize*3/2, 0]).add(voff)
     
    # Racked ball positions
    ballPosition = (i) ->
      switch i
        when 1 then cuestartPos()
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
      p = ballPosition(i).add(point(0.4, 0.4))
      balls.push new Circle(p.e(1), p.e(2), p.e(3), {
        radius: ballRadius
        color: BALL_COLORS[i-1]        
        speed: 0
        angVel: 0
        efficiency: 1
        pocketed: false
        moving: false
        number: i-1
        }) 
    
    # Save original positions for replay
    for b in balls
      b.origPos = b.pos.dup()
      
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
    
  # Unused but working
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

  drawBallNumber = (b) ->
    context.fillStyle    = '#FFFFFF'
    context.font         = '10px Arial sans-serif'
    context.textBaseline = 'top'
    context.fillText b.number, b.x()-5, b.y()-5
      
  drawJaw = (j) ->
    context.beginPath()
    context.arc(j.x(), j.y(), j.radius, 0, Math.PI*2, false)
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
    # if DRAW_GUIDES
    #       pt = $V([jawArcRadius, jawArcRadius, 0])
    #       context.save()
    #       context.strokeStyle = 'grey'
    #       for j in jaws
    #         drawJaw(j)
      
  drawBalls = ->
    for ball in balls when not ball.pocketed
      context.fillStyle = ball.color
      context.beginPath()
      context.arc(ball.x(), ball.y(), ball.radius, 0, Math.PI*2, true);
      context.closePath();
      context.fill();
      drawBallNumber(ball) unless ball.number == 0 or ball.number == 15

  drawCue = ->
    # Wait until cue image fully loaded
    return unless lastCuePos? and cueImg.width > 0 and cueImg.height > 0
    # Cue start point relative to ball
    ogCuePos = point(-(cueImg.width-ballRadius/1.5)+cueCenterOffset, -(cueImg.height+ballRadius/1.5))
        
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
    
    if DRAW_GUIDES and lastCuePos?
      cuev = balls[0].pos.subtract(lastCuePos).x(10)
      # draw guide line
      context.save()
      drawLine(new Line(balls[0].pos.e(1), balls[0].pos.e(2), cuev.e(1), cuev.e(2)))
      context.restore()
  
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
    s.move displacement(ts, s.velocity)
      
  ballIsMoving = (b) ->
    b.speed > Sylvester.precision
    
  ballsMoving = ->
    (b for b in balls when ballIsMoving(b)).length

  # returns # non-pocketed balls belonging to a player
  numBallsInPlay = (player) ->
    (b for b in playerBalls(player) when !b.pocketed and (b != eightBall())).length

  # returns all balls belonging to player
  playerBalls = (player) -> 
    if playerColors[currentPlayer]
      (b for b in balls when ballColor(b) == playerColors[currentPlayer] and b != eightBall())
    else # return all balls if no one has sunk a ball yet
      balls[1..NUM_BALLS]
      
  applyFrictionToBalls = (balls) ->
    for b in balls when b.moving
      # slow ball speed from friction
      b.speed = Math.max(b.speed - frictionDecelaration, 0)
      # Adjust moving flag in case ball has stopped
      b.moving = ballIsMoving(b)
  
  removePocketed = (ball) ->
    ball.pocketed = true
    ball.speed = 0
    ball.pos = Vector.Zero(3)
    pocketedOnTurn.push ball
    
    if isColorBall(ball)
      # if first pocketed ball, we need to set the player side
      unless playerColors[currentPlayer]
        # TODO: When more than one color pocketed, 
        # give player choice or use color with highest count
        playerColors[currentPlayer] = ballColor(ball)
        playerColors[otherPlayer(currentPlayer)] = otherColor(ball)
        console.dir playerColors
    
  otherPlayer = (player) ->
    (player % 2) + 1
    
  ballColor = (ball) ->
    if ball.number < 8 then 'solid' else 'stripe'
    
  otherColor = (ball) ->
    if ballColor(ball) == 'solid' then 'stripe' else 'solid'
    
  cueBall = ->
    balls[0]

  eightBall = ->
    balls[15]

  isScratched = ->
    cueBall().pocketed
  
  isEightBallScratched = ->
    # TODO: Take current player's color into consideration
    eightBall().pocketed and (numBallsInPlay(currentPlayer) > 0)
    
  isOwnBallPocketed = ->
    pocketedOnTurn.length > 0 and
      # last pocketed should be player color
      ballColor(pocketedOnTurn[pocketedOnTurn.length-1]) == playerColors[currentPlayer]
    
  isColorBall = (ball) ->
    ball != cueBall() && ball != eightBall()
  
  isGameOver = ->
    eightBall().pocketed or 
      (isScratched() and (numBallsInPlay(currentPlayer) == 0))
  
  isEndOfTurn = ->
    return false unless shooting
    isScratched() or !isOwnBallPocketed() or eightBall().pocketed
  
  # Determines which player won iff game is over
  getWinner = ->
    if (numBallsInPlay(currentPlayer) == 0) and !isScratched()
      currentPlayer
    else 
      otherPlayer(currentPlayer)
    
  resetCueBall = ->
    b = cueBall()
    b.pocketed = false
    b.pos = cuestartPos()
      
  newGame = ->
    playerColors = {}
    
    for b in balls
      b.pos = b.origPos.dup()
      b.pocketed = false
      b.speed = b.angVel = 0
      
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

      # helper function for checking potential collision and saving 
      # collisions details if any
      # @returns {float} collision time if pending collision, else null
      detectCollisionHelper = (s1, s2, objType) ->
        s1.velocity = s1.direction.x(s1.speed)
        s2.velocity = s2.direction.x(s2.speed)
        s1.displacement = displacement(ts, s1.velocity)
        s2.displacement = displacement(ts, s2.velocity)

        [collisionTime, collisionNormal] = collisions.detectCollision s1, s2
        
        return null unless collisions.isImpendingCollision(collisionTime)
        #console.log "#{objType} collision in #{collisionTime}!"

        m = Math.min(mn, collisionTime)
        # If collision is most imminent, save objects' info
        if m < mn
          mn = m
          n = collisionNormal.dup()
          ob1 = s1
          ob2 = s2
          tp = objType
        
        collisionTime
      
      # Function for resolving ball's linear and angular velocities
      # when colliding with a cushion
      # @param {Circle} ball
      # @param {Line} wall
      # @param {Vector} normal - normal of collision
      # @param {Number} cushion efficiency
      # @param {Number} proportion or angular velocity lost (between 0, 1)
      resolveBallCushionCollision = (ball, cushion, normal, prop) ->
        # angular velocity decreases by some amount phi
        phi = ball.angVel * prop
        ball.angVel -= phi
        # apply impulse to calculate resulting change in linear velocity
        # impulse = I*phi/radius
        # I = (ball.mass * ball.radius^2) / 4
        # change in linear velocity = relative velocity + (I*phi/m) * tang
        # = (ball.radius^2 * phi)/4 * tang
        tang = normal.clockwiseNormal()
        velchange = tang.x(0.4 * phi * ball.radius * ball.radius)
        ball.velocity = ball.velocity.subtract(velchange)
        # then apply perpendicular impulse as usual
        collisions.resolveInelasticCollisionFixed(ball, cushion, normal)
        
      # Check each ball for collision
      for i in [0...balls.length]
        b1 = balls[i]
        continue if b1.pocketed
        
        # check for collisions between balls
        for j in [(i+1)...balls.length]
          b2 = balls[j]
          continue if b2.pocketed
          
          if b1.moving || b2.moving
            #console.log "detecting collision b/w balls #{b1.number}, #{b2.number}"
            detectCollisionHelper b1, b2, "ball"
            
        # check for collisions with cushions    
        if b1.moving
          for w in cushions
            #console.log "detecting collision b/w ball #{b1.number} and cushion"
            detectCollisionHelper b1, w, "wall"
        
          # check for ball pocketing
          for p in pockets
            detectCollisionHelper(b1, p, "pocket")
              
      # if there is no collision we are finished
      break if mn == 2
      
      # there is a collision
      # move balls to collision position
      if mn > Sylvester.precision
        for b in balls when b.moving
          moveObject(b, mn*ts)

      # resolve collisions
      if tp == "wall"
        resolveBallCushionCollision ob1, ob2, n, 0.2
        ob1.speed = ob1.velocity.mag()
        ob1.direction = ob1.velocity.toUnitVector()
      else if tp == "pocket"
        console.log "pocketing ball #{ob1.number}"
        removePocketed ob1
      else
        #console.log "resolving collision b/w #{ob1.number} & #{ob2.number}"
        # Save collision speed for collision sound playback at proper volume
        ob1.collided = true
        ob1.collisionSpeed = ob1.velocity.subtract(ob2.velocity).mag()
        
        collisions.resolveCollision ob1, ob2, n
        ob1.speed = ob1.velocity.mag()
        ob2.speed = ob2.velocity.mag()
        if ob1.moving = ballIsMoving(ob1)
          ob1.direction = ob1.velocity.toUnitVector()
        if ob2.moving = ballIsMoving(ob2)
          ob2.direction = ob2.velocity.toUnitVector()
        
      # decrease time and repeat
      ts *= (1 - mn)
    # End while ts > 0
    
    # move balls for the last section (no collisions)
    for b in balls
      moveObject(b, ts) if b.moving
      # Use callbacks if any
      if b.collided
        onCollisionCb(b.collisionSpeed) if onCollisionCb?
        b.collided = false
    
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
    unless ballsMoving()
      drawCue() 
      shotFinished() if shooting
  
  # animate all objects
  animate = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = timeNow - lastTime
      moveBalls(elapsed, balls, cushions, jaws)
        
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
  
  # Moves cue left/right from center
  moveCue = (dir) ->
    cueCenterOffset += if dir == 'l' then 1 else -1
  
  # Making the shot
  initShot = ->
    console.log "Starting shot..."
    # Freeze cue direction vector
    cueVec = balls[0].pos.subtract(lastCuePos).toUnitVector()
    cueStartTime = new Date().getTime()
    cueing = true
    
  # Shoot!
  makeShot = (player, cueSpeed) ->
    cueing = false
    shooting = true
    currentPlayer = player
    pocketedOnTurn = []
    c = cueBall()
    c.direction = cueVec.dup()
    c.speed = cueSpeed
    c.moving = true
    c.angVel = cueCenterOffset/25 * 2 * Math.PI
    cueCenterOffset = 0
    console.debug "player #{player} shooting with speed: #{cueSpeed}, dir #{cueVec.inspect()}, english: #{c.angVel}"
  
  shotFinished = ->
    # handle end of turn
    if isEndOfTurn()  
      # use callback if one was provided
      if onEndTurnCb?
        onEndTurnCb(playerColors) 
      else if isGameOver()
        newGame()
        
    resetCueBall() if isScratched()
    shooting = false
      
  # Return public functions
  {updateCue, moveCue, initShot, makeShot, newGame, isGameOver, otherPlayer, getWinner}

root = exports ? window
root.PoolTable = PoolTable

