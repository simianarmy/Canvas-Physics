# Creates and animates canvas 

#= require ./vec
#= require ./collisions
#= require ./Line
#= require ./Circle

NUM_GROUPED_CIRCLES = 3
NUM_FREE_CIRCLES    = 3
CIRCLE_RADIUS       = 20
CIRCLE_COLORS       = ['#00A308', '#FF0066', '#3366FF', '#CCCCCC', '#FFCCFF']
MAX_VELOCITY_X      = 200
MAX_VELOCITY_Y      = 50

# the scene object
scene = ->
  canvas = null
  lastTime = 0
  circles = null
  walls = null
  canvas = null
  context = null
  ticks = 0
  animating = false
  changeY = false
  freeY   = false
  
  # setup
  setup = ->
    console.log "setting up objects"
    
    # fetch and save the canvas context
    canvas = $("#maincanvas").get(0)
    context = canvas.getContext('2d')
    # translate world for origin at bottom left
    context.scale(1, -1)
    context.translate(0, -canvas.height)
    
    # Make walls = canvas border
    walls = [new Line(0, 0, 0, canvas.height, {mass: Infinity}) # left
      ,new Line(canvas.width, 0, 0, canvas.height, {mass: Infinity}) # right
      ,new Line(0, 0, canvas.width, 0, {mass: Infinity}) # bottom
      ,new Line(0, canvas.height, canvas.width, 0, {mass: Infinity}) # top
    ]
      
    circles = []
    cx = CIRCLE_RADIUS * 2
    cy = canvas.height / 2
  
    # Make free circles  
    for i in [0...NUM_FREE_CIRCLES]
      circles.push createFreeCircle(cx, cy, i)
      cx += CIRCLE_RADIUS * 3
      
    cx += CIRCLE_RADIUS * 2
  
    # Make fixed circles
    for i in [0...NUM_GROUPED_CIRCLES]
      circles.push new Circle(cx, cy, 0, {
        radius: CIRCLE_RADIUS,
        velocity: Vector.create([0, 0, 0])
        color: CIRCLE_COLORS[0]
      })
      cx += CIRCLE_RADIUS * 2 + 1

    console.log "Created circle " + c for c in circles
    drawScene()
    
  # Return a random circle color
  randomCircleColor = ->
    CIRCLE_COLORS[getRandomInt(1, CIRCLE_COLORS.length)]
    
  # Return a y-value for a circle
  circleY = -> 
    if freeY then getRandom(-MAX_VELOCITY_Y, MAX_VELOCITY_Y) else 0
      
  # Create and return a new (free) circle
  createFreeCircle = (x, y, i) ->
    velx = getRandom(-MAX_VELOCITY_X, MAX_VELOCITY_X)
    new Circle(x, y, 0, {
      radius: CIRCLE_RADIUS
      velocity: Vector.create([velx, circleY(), 0])
      color: randomCircleColor()
    })
      
  # Assign new y-value to all circles
  updateCircleY = ->
    for c in circles
      vel = c.velocity
      c.velocity = $V([vel.e(1), circleY(), vel.e(3)])
    
  # Update number of balls on screen
  updateBallCount = (nballs) ->
    console.log "new ball count: " + nballs
    diff = nballs - circles.length
    if diff > 0
      # Add balls
      for i in [1..diff]
        circles.push createFreeCircle(getRandom(0, canvas.width), canvas.height/2, i)
    else
      # remove balls
      circles.pop() for i in [1..(circles.length-nballs)]
      
    console.log "circles now: " + circles.length
    
  # Draw a circle on the canvas
  drawCircle = (c) ->
    context.fillStyle = c.color
    context.beginPath()
    context.arc(c.pos.e(1), c.pos.e(2), c.radius, 0, Math.PI*2, true); 
    context.closePath();
    context.fill();
    
  # toggle the animation on and off
  toggleAnimation = ->
    animating = !animating
    lastTime = 0
    tick()

  # toggle circles' y-freedom...only used to 'free' them right now
  toggleCirclesY = (checked) ->
    changeY = true
    freeY   = checked
      
  # draw all objects on the canvas
  drawScene = ->
    context.clearRect 0, 0, canvas.width, canvas.height
    # Draw circles
    drawCircle c for c in circles
    
  # animate all objects
  animate = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = timeNow - lastTime
      collisions.checkCollisions elapsed, circles, walls

    # change vertical velocity components if toggled
    if changeY
      updateCircleY() 
      changeY = false
      
    lastTime = timeNow

  # tick funtion
  tick = ->
    requestAnimFrame(tick) 
    drawScene()
    animate() if animating
    ticks += 1

  # Initialize
  setup()
  
  # Return public functions
  {toggleAnimation, toggleCirclesY, updateBallCount}

root = exports ? window
root.scene = scene

