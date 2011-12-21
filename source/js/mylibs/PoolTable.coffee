# PoolTable.coffee 

#= require ./vec
#= require ./collisions
#= require ./Line
#= require ./Circle

NUM_BALLS           = 16
BALL_RADIUS         = 10
POCKET_SIZE         = 1.7
JAW_SIZE            = 0.5
DECELARATION        = 0
CUSHION_EFFICIENCY  = 0
BALL_COLORS         = ['grey', 'yellow', 'blue', 'red', 'purple', 'orange', 'green', 'maroon',
                      'yellow', 'blue', 'red', 'purple', 'orange', 'green', 'maroon', 'black']

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
  frictionDecelartion = opts.decelaration ? DECELARATION
  cushionEfficiency = opts.efficiency ? CUSHION_EFFICIENCY
  cueImg    = null
  cuePos    = null
  cueRot    = 0
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
  
  # setup
  setup = ->
    console.log "setting up game objects"
    rs = ballRadius * pocketSize
    rd = ballRadius * Math.sqrt(2.0) * pocketSize
    
    console.log "Table size: #{tableSize}\nball radius: #{ballRadius}\npocket size: #{pocketSize}\njaw size: #{jawSize}"
    console.log "rs: #{rs}, rd: #{rd}"
    # Make table cushions
    # Assuming the table is aligned vertically, major axis is height
    cushions = [new Line(rd, 0, tableSize-rd*2, 0, {mass: Infinity}) # top
      ,new Line(0, rd, 0, tableSize-rd-rs, {mass: Infinity}) # left top
      ,new Line(0, tableSize+rs, 0, tableSize-rd-rs, {mass: Infinity}) # left bottom
      ,new Line(rd, tableSize*2, tableSize-rd*2, 0, {mass: Infinity}) # bottom
      ,new Line(tableSize, rd, 0, tableSize-rd-rs, {mass: Infinity}) # right top
      ,new Line(tableSize, tableSize+rs, 0, tableSize-rd-rs, {mass: Infinity}) # right bottom
    ]
    # Offset cushions from canvas border so that lines draw correctly
    voff = $V([xoffset, yoffset, 0])
    for wall in cushions
      wall.pos = wall.pos.add(voff)
      
    # pw is the radius of the circular arcs at the pocket entrances
    jawArcRadius = pw = rs * jawSize
    
    # Use walls as guide to draw jaws
    for wall in cushions
      if wall.vec.e(1) == 0 # this is a vertical wall
        if wall.pos.e(1) > tableSize/2 # its on the right
          jaws.push wall.pos.add($V([pw, 0, 0]))
          jaws.push wall.pos.add(wall.vec).add($V([pw, 0, 0]))
        else # its on the left
          jaws.push wall.pos.subtract($V([pw, 0, 0]))
          jaws.push wall.pos.add(wall.vec).subtract($V([pw, 0, 0]))
      else # this is a horizontal wall
        if wall.pos.e(2) > tableSize # its on the bottom
          jaws.push wall.pos.add($V([0, pw, 0]))
          jaws.push wall.pos.add(wall.vec).add($V([0, pw, 0]))
        else # its on the top
          jaws.push wall.pos.subtract($V([0, pw, 0]))
          jaws.push wall.pos.add(wall.vec).subtract($V([0, pw, 0]))
    
    # Make balls
    createBalls()
    
    # Make pool cue
    createCue()
    
    drawScene()
    
  createBalls = ->
    r = ballRadius * 1.02
    cuestart = $V([tableSize/2, 2*tableSize/5, 0]).add(voff)
    y = Math.sqrt(3.0) * r
    tristart = $V([tableSize/2, tableSize*3/2, 0]).add(voff)
    
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
        displacement: $V([1, 0, 0]) # direction
        velocity: Vector.Zero()
        pocketed: false
        moving: false
        }) 
  
  createCue = ->
    cueImg = new Image
    cueImg.src = '/img/poolcue.png'
    
  # Convenience vector creator for points
  point = (x, y) ->
    $V([x, y, 0])
    
  drawTable = ->
    # Draw the cushions
    context.save()
    context.strokeStyle = 'black'
    for wall in cushions
      endpoint = wall.pos.add(wall.vec)
      context.moveTo wall.pos.e(1), wall.pos.e(2)
      context.lineTo endpoint.e(1), endpoint.e(2)
    context.stroke()
    context.restore()
    
    # Draw the pocket corneres
    pt = $V([jawArcRadius, jawArcRadius, 0])
    context.save()
    context.strokeStyle = 'grey'
    for j in jaws      
      # scale for ellipse?
      #context.scale(0.75, 1)
      context.beginPath()
      context.arc(j.subtract(pt).e(1), j.add(pt).e(2), jawArcRadius*2, 0, Math.PI*2, false)
      context.stroke()
      context.closePath()

    # Draw the pockets
    xx = voff.e(1) + tableSize
    yy = voff.e(2) * 2/3
    b = 1
    pockets = [point(yy+b/3, yy+b/3), 
      point(xx, yy+b/3),
      point(yy, xx),
      point(xx+b/3, xx),
      point(yy+b/3, xx*2-b),
      point(xx, xx*2-b),
    ]
    pt = point(ballRadius * pocketSize, ballRadius * pocketSize)
    for p in pockets
      context.beginPath()
      context.arc(p.subtract(pt).e(1), p.add(pt).e(2), jawArcRadius, 0, Math.PI*2, false)
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
    cuePos ?= balls[0].pos.subtract($V([0, ballRadius, 0]))
    context.save()
    context.translate cuePos.e(1), cuePos.e(2)
    context.rotate cueRot
    context.translate(-cueImg.width/2, -cueImg.height)
    context.drawImage(cueImg, 0, 0, cueImg.width, cueImg.height)
    context.restore()
    
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
    drawCue()
    
  # animate all objects
  animate = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = timeNow - lastTime
      collisions.checkCollisions elapsed, balls, cushions
      
    lastTime = timeNow

  # tick funtion
  tick = ->
    requestAnimFrame(tick) 
    drawScene()
    animate() if animating
    ticks += 1

  # Initialize
  setup()
  
  # Public functions
  
  updateCue = (mousePos) ->
    cueRotation = (ballPos, mpos) ->
      v = ballPos.subtract(mpos.add(voff))
      if v.mag() > 0
        ang = Math.atan2(v.e(2), v.e(1))
        ang * 180 / Math.PI
      else
        console.log "error"
    
    cueRot = cueRotation balls[0].pos, $V([mousePos.x, mousePos.y, 0])
    console.log "cue rotation: #{cueRot}"
    drawScene()
    
  # Return public functions
  {updateCue}

root = exports ? window
root.PoolTable = PoolTable

