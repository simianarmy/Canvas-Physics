# springs.js
# 
# main() for the springs page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Math
#= require mylibs/Spring
#= require mylibs/Circle
#= require mylibs/Canvas
#= require mylibs/particles
#= require mylibs/canvasEvents
#= require mylibs/collisions

$(document).ready ->
  $canvas = $("#maincanvas")
  canvasEl = $canvas.get(0)
  canvas = new Canvas(canvasEl)
  canvas.setOrigin('bottomleft')
  events = canvasEvents canvasEl
  elapsed = lastTime = 0
  sim = 'force'
  paused = true
  updateObjectsFn = null
  # spring properties
  springLen = 0
  springMinLen = 0
  springElasticity = 0
  springDamping = 0
  elasticLimit = 0
  compressiveness = 0
  # particle properties
  particleMass = 0
  # world properties
  gravity = 10
  energy = null
  forceOnEnd = Vector.Zero()
  dhmParams = null
  # objects 
  objects = []
  drawableText = []
  spring = null
  particle = null
  walls = []
  # mouse throwing variables
  mouseOnBall = false
  lastDragPoint = null
  lastDragTime = 0
  throwTime = 0
  posOffset = 0
  dragPoints = []
  
  # Collect control values
  updateControls = ->
    springLen = parseInt $('input[name=springLen]').val()
    springMinLen = parseInt $('input[name=springMinLen]').val()
    springElasticity = parseInt $('input[name=springElasticity]').val()
    springDamping = parseFloat $('input[name=springDamping]').val()
    elasticLimit = parseInt Math.max($('input[name=elasticLimit]').val(), springLen)
    compressiveness = $('input[name=compressiveness]:checked').val()
    particleMass = parseInt $('input[name=pMass]').val()
    
    # Display updated values next to sliders
    $('#springLen').html(springLen)
    $('#springMinLen').html(springMinLen)
    $('#springElasticity').html(springElasticity)
    $('#springDamping').html(springDamping)
    $('#elasticLimit').html(elasticLimit)
    $('#pMass').html(particleMass)
    
    spring? && updateSpring(spring)
    particle? && updateParticle(particle)
    walls = [new Line(0, 0, canvas.width, 0),
      new Line(canvas.width, 0, 0, canvas.height),
      new Line(0, 0, 0, -canvas.height),
      new Line(0, canvas.height, canvas.width, 0)
      ]
    
  # update spring properties (from controls)
  updateSpring = (spring) ->
    spring.elasticity = springElasticity
    spring.damping = springDamping
    spring.minLength = springMinLen
    spring.elasticLimit = elasticLimit
    
    if compressiveness == 'loose'
      spring.compressiveness = Spring.LOOSE 
    else if compressiveness == 'rigid'
      spring.compressiveness = Spring.RIGID
    else
      spring.compressive = true
    
    
  updateParticle = (p) ->
    p.mass = particleMass
    p.radius = Math.max(particleMass / 2, 1)
    p.speed = 0
    p.direction = $V([0, 0, 0])
    energy = null
    dhmParams = Spring.initialDHMParams()
    
  # move spring endpoint up or down
  moveSpringEnd = (dir) ->
    if dir == 'u'
      spring.pnt2 = spring.pnt2.add($V([0, 5, 0]))
    else
      spring.pnt2 = spring.pnt2.subtract($V([0, 5, 0]))
    
  # Initiate user 'throw' of a particle on spring
  # @param {Vector} p current mouse position
  throwBall = (p) ->
    ts = ((new Date).getTime() - dragPoints[0][0]) / 1000
    return unless ts > 0
    dv = p.subtract(dragPoints[0][1])
    particle.velocity = dv.divide(ts)
    particle.speed = Math.min(particle.velocity.mag(), 150)
    if (particle.speed > 0)
      particle.direction = particle.velocity.toUnitVector()
    console.log "ball speed: #{particle.speed}"
    console.log "ball dir: #{particle.direction.inspect()}"
    paused = false
    
    # Calculate DHM params now too
    initPos = p.e(2) - posOffset - canvas.height/2
    initVel = dv.e(2)
    dhmParams = Spring.calculateDHMParams(initPos, initVel, springElasticity, springDamping)
    throwTime = (new Date).getTime()      
    
  # Force on particle due to spring simulation
  forceFromStringSim = ->
    console.log "init force from spring simulation"
    sim = 'force'
    $('#instructions').show().html($('#ffsInstructions').html())
    # Create spring & particle to attach to an endpoint
    # Fix spring end to bottom center
    spring = new Spring($V([canvas.width/2, 0, 0]), $V([0, springLen, 0]), 
      $V([0, 0, 0]), 
      $V([0, 10, 0]),
      springLen)
    updateSpring spring
    
    objects = [spring]
    updateObjectsFn = updateForceSim
    # start animation
    paused = false
  
  # Moving particle on a spring simulation
  particleOnStringSim = ->
    console.log "particle on spring simulation"
    sim = 'particle'
    $('#instructions').show().html($('#posInstructions').html())
    # Create spring & particle to attach to an endpoint
    # Fix spring end to bottom center
    spring = new Spring($V([canvas.width/2, canvas.height-100, 0]), $V([0, -springLen, 0]), 
      $V([0, 0, 0]), 
      $V([0, 0, 0]),
      springLen)
    updateSpring spring
    
    particle = new Circle(canvas.width/2, canvas.height-springLen, 0, {
      color: 'black'
    })
    updateParticle particle
    objects = [spring, particle]
    updateObjectsFn = updateParticleEnergySim
    # start animation
    paused = false
    
  # DHM simulation
  dhmSim = ->
    console.log "DHM simulation"
    sim = 'dhm'
    $('#instructions').show().html($('#posInstructions').html())
    particle = new Circle(canvas.width/2, canvas.height/2, 0, {
      color: 'black'
    })
    updateParticle particle
    objects = [particle]
    dhmParams = Spring.initialDHMParams()
    updateObjectsFn = updateDHMSim
    # start animation
    paused = false
    
  # Multiple connected springs simulation
  multiSpringSim = ->
    console.log "Multispring simulation"
    sim = 'multi'
    
    # Start w/ 2 springs & 2 particles
    s1 = new Spring($V([canvas.width/2, canvas.height-40, 0]), $V([0, -springLen, 0]), 
      $V([0, 0, 0]), 
      $V([0, 0, 0]),
      springLen)
    updateSpring s1
    s2 = new Spring($V([s1.endpoint().e(1), s1.endpoint().e(2), 0]), $V([0, -springLen, 0]), 
      $V([0, 0, 0]), 
      $V([0, 0, 0]),
      springLen)
    updateSpring s2
    
    # particle attached to s1 & s2
    pa = new Circle(s1.x(), s1.y(), 0, {
      color: 'black',
      id: 'p0'
    })
    updateParticle pa
    # particle attached to s1 & s2
    p1 = new Circle(s2.x(), s2.y(), 0, {
      color: 'black',
      id: 'p1'
    })
    updateParticle p1
    # particle attached to s2 endpoint
    p2 = new Circle(s2.endpoint().e(1), s2.endpoint().e(2), 0, {
      color: 'black',
      id: 'p2'
    })
    updateParticle p2

    # start last particle moving sideways
    p2.speed = 100
    p2.direction = $V([1, -1, 0])
    s2.evel = p2.direction.x(p2.speed)
    
    # s1 point is fixed
    # set particle/spring pairings for force calculations
    # end: 1 = particle at start of spring, 2 = at end of spring
    pa.springs = [{spring: s1, end: 1}]
    p1.springs = [{spring: s1, end: 2}, {spring: s2, end: 1}]
    p2.springs = [{spring: s2, end: 2}]

    objects = [s1, s2, pa, p1, p2]
    updateObjectsFn = updateMultiSpringSim
    # start animation
    paused = false
    
  # Draw objects on canvas
  drawScene = (objects, ts) ->
    canvas.clear()
    textY = 10
    for text in drawableText
      canvas.drawText(text, 10, textY)
      textY += 25
    
    for obj in objects
      switch obj.name
        when 'Circle'
          canvas.drawCircle obj

        when 'Spring'
          canvas.drawLineFromPoints obj.pnt1, obj.pnt2
          
  queueOutput = (txt) ->
    console.log txt
    drawableText.push txt
    
  checkCollisions = (ts) ->
    for p in objects when p.name == 'Circle'
      # Check for particle bounce against edges
      for w in walls
        res = collisions.circleWallCollision p, w
        console.log "p#{p.id} vs wall in #{res[0]}"
        if collisions.isImpendingCollision(res[0]) || (res[0] == collisions.EMBEDDED)
          collisions.resolveCollisionFixed p, res[1]
          p.moveByTime(ts) # move particle away from wall
          if p.springs?
            # spring(s) endpoint property update
            updateConnectingSprings(p)
          else if spring?
            spring.pnt2 = l
            
          break        
    
  # update spring endpoint(s) with particle's new position & velocity
  updateConnectingSprings = (p) ->
    for sp in p.springs
      if sp.end == 1
        sp.spring.pnt1 = p.pos
        sp.spring.svel = p.velocity
      else
        sp.spring.pnt2 = p.pos
        sp.spring.evel = p.velocity
              
  # calculate article position/speed from springs force & gravity
  # @param {Circle} particle
  # @param {Number} ts timestep
  updateParticleFromSpringForces = (p, ts, count=1) ->
    return if count > 10 # prevent inf. recursion
    ten = $V([0, p.mass * gravity, 0])
    for sp in p.springs
      f = sp.spring.forceOnEndpoint({reverse: sp.end == 1})
      if f == Spring.BOUNCE
        console.log "BOUNCE!"
        # resolve collision
        collisions.resolveCollisionFixed p, sp.spring.toVector()
        p.pos = p.pos.add(p.direction.x(p.speed*ts))
        updateConnectingSprings p
        #console.log "new direction (#{p.id}): #{p.direction.inspect()}"
        updateParticleFromSpringForces(p, ts, count + 1)
        return
      else
        ten = ten.add(f)
    
    # apply force to particle
    acc = ten.divide(p.mass)    
    p.pos = p.pos.add(p.direction.x(p.speed*ts)).add(acc.x(ts*ts/2))
    p.setVelocity p.velocity.add(acc.x(ts))
    updateConnectingSprings p
    
    #console.log "new direction (#{p.id}): #{p.direction.inspect()}"

  # update function for force simulation
  updateForceSim = (ts) ->
    # calculate force on endpoint
    f = spring.forceOnEndpoint()
    
    if (f == Spring.BOUNCE)
      console.log("BOUNCE")
      forceOnEnd = "BOUNCE"
    else
      forceOnEnd = f.inspect()
    queueOutput "force at endpoint: #{forceOnEnd}"
    queueOutput "spring length: #{spring.currentLength()}"
    
  # update function for particle simulation
  updateParticleEnergySim = (ts) ->
    # calculate new particle properties
    next = particles.particleOnSpring(spring, particle, energy, ts, gravity)
    
    queueOutput "particle pos: #{next.pos.inspect()}"
    queueOutput "particle speed: #{next.speed}"
    queueOutput "total energy: #{next.totalEnergy}"
    
    spring.pnt2 = next.pos.dup()
    particle.pos = next.pos.dup()
    particle.speed = next.speed
    
    if particle.speed > 0
      queueOutput "particle direction: #{next.velocity.inspect()}"
      particle.direction = next.velocity.dup()
    energy = next.totalEnergy
    queueOutput "spring length: #{spring.currentLength()}"
    
  updateDHMSim = (ts) ->
    if throwTime > 0
      t = ((new Date()).getTime() - throwTime) / 1000
      pos = Spring.getOscillatorPosition(springElasticity, springDamping, dhmParams, t)
      speed = Spring.getOscillatorSpeed(springElasticity, springDamping, dhmParams, t, pos)
      queueOutput "DHM pos: #{pos}"
      queueOutput "DHM speed: #{speed}"
      queueOutput "motion: #{dhmParams.motion}"
      particle.moveTo $V([particle.x(), pos + canvas.height/2, 0])
      particle.speed = speed
      queueOutput "particle pos: #{particle.pos.inspect()}"
      queueOutput "particle speed: #{particle.speed}"

  updateMultiSpringSim = (ts) ->
    for p in objects when p.name == 'Circle'
      updateParticleFromSpringForces(p, ts)
      
    # adjust spring length and endpoint velocity based on force value
  # animate all objects
  update = ->
    # Pass latest timestep to the collision detection function
    timeNow = (new Date()).getTime()
    if lastTime != 0
      elapsed = (timeNow - lastTime) / 1000
      elapsed = 0.1 if elapsed > 0.1
      drawableText = []
  
      updateObjectsFn.call(@, elapsed)
      checkCollisions(elapsed)
      
    lastTime = timeNow

  # tick funtion
  tick = ->
    requestAnimFrame(tick) 
    unless paused
      update()
    
    drawScene(objects, elapsed)
  
  # convert mouse coordinates to vector with proper y-orientation  
  pointToVec = (p) ->
    $V([p.x, canvas.height-p.y, 0])
  
  # prevent arrow keys from scrolling around
  keyDown = (evt) ->
    console.log "on key down #{evt.keyCode}"
    evt.preventDefault()
    evt.stopPropagation()
    return false if paused
    dir = null

    switch evt.keyCode
      when 38, 87
        dir = 'u'
      when 40, 83
        dir = 'd'

    moveSpringEnd(dir) if dir?
      
  mouseDown = (evt) ->
    p = events.convertEventToCanvas(evt)
    mouseOnBall = particle && collisions.pointInCircle(pointToVec(p), particle)      
    if mouseOnBall
      paused = true
      energy = null
      posOffset = p.y - particle.y()
      dragPoints.push([(new Date()).getTime(), pointToVec(p)])
    
  mouseUp = (evt) ->
    p = events.convertEventToCanvas(evt)
    if mouseOnBall
      throwBall pointToVec(p)
    mouseOnBall = false
      
  mouseMove = (evt) ->
    if mouseOnBall
      lastDragPoint = events.convertEventToCanvas(evt)
      particle.pos = pointToVec(lastDragPoint)
      spring.pnt2 = particle.pos if spring?
      dragPoints.push([(new Date()).getTime(), particle.pos])
      dragPoints.shift() if dragPoints.length > 5
      
  $('.forceFromSpring').click(forceFromStringSim)
  $('.particleOnSpring').click(particleOnStringSim)
  $('.dhm').click(dhmSim)
  $('.multiSpring').click(multiSpringSim)
  
  # Update simulation controls
  $('#controls input').change(updateControls);
  
  $('#info span').hide()
  $(document).keydown(keyDown)
  $canvas.mousedown(mouseDown)
  $canvas.mouseup(mouseUp)
  $canvas.mousemove(mouseMove)
  
  updateControls()
  tick()
  