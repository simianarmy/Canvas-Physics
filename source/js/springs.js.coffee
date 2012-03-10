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
    p.radius = Math.max(particleMass / 5, 1)
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
      radius: particleMass/2,
      color: 'black',
      mass: particleMass,
      speed: 0,
      direction: $V([0, -1, 0])
    })
    objects = [spring, particle]
    # start animation
    paused = false
    
  # DHM simulation
  dhmSim = ->
    console.log "DHM simulation"
    sim = 'dhm'
    $('#instructions').show().html($('#posInstructions').html())
    particle = new Circle(canvas.width/2, canvas.height/2, 0, {
      radius: particleMass/2,
      color: 'black',
      mass: particleMass,
      speed: 0,
      direction: $V([0, 0, 0])
    })
    objects = [particle]
    dhmParams = Spring.initialDHMParams()
    # start animation
    paused = false
    
  # Multiple connected springs simulation
  multiSpringSim = ->
    console.log "Multispring simulation"
    sim = 'multi'
    
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
    drawableText.push txt
    
  checkCollisions = ->
    return unless particle?
    
    # Check for particle bounce against edges
    l = particle.pos
    pr = particle.radius
    change = false
    # check x
    if l.e(1) < pr
      l.elements[0] += (pr - l.e(1)) * 2
      particle.direction.elements[0] = Math.abs(particle.direction.e(1))
      change = true
    else if l.e(1) > (canvas.width - pr)
      l.elements[0] -= Math.abs((l.e(1) - canvas.width - pr) * 2)
      particle.direction.elements[0] = -Math.abs(particle.direction.e(1))
      change = true
    # check y
    if l.e(2) < pr
      l.elements[1] += (pr - l.e(2)) * 2
      particle.direction.elements[1] = Math.abs(particle.direction.e(2))
      change = true
    else if l.e(2) > (canvas.height - pr)
      l.elements[1] -= Math.abs((l.e(2) - canvas.height - pr) * 2)
      particle.direction.elements[1] = -Math.abs(particle.direction.e(2))
      change = true
    
    # double check
    if change
      if l.e(1) < pr
        l.elements[0] = pr
        particle.direction.elements[0] = 0
      else if l.e(1) > (canvas.width - pr)
        l.elements[0] = canvas.width - pr
        particle.direction.elements[0] = 0
      if l.e(2) < pr
        l.elements[1] = pr
        particle.direction.elements[1] = 0
      else if l.e(2) > (canvas.height - pr)
        l.elements[1] = canvas.height - pr
        particle.direction.elements[1] = 0
      
      particle.pos = l
      spring.pnt2 = l if spring?
    
  # calculate article position/speed from springs force & gravity
  # @param {Circle} particle
  # @param {Array} springs all spring objects
  # @param {Number} ts timestep
  updateParticleFromSpringForces = (p, springs, ts) ->
    ten = $V([0, p.mass * gravity, 0])
    for sp in springs
      f = sp.forceOnEndpoint()
      if f == Spring.BOUNCE
        console.log "BOUNCE!"
        # resolve collision
        return updateParticleFromSpringForces(p, springs, ts)
      else
        ten = ten.add(f)

    # apply force to particle
    acc = ten.divide(particle.mass)
    queueOutput "force on particle from spring: #{f.inspect()}"
    
    particle.pos = particle.pos.add(particle.direction.x(particle.speed*ts)).add(acc.x(ts*ts/2))
    particle.velocity = particle.velocity.add(acc.x(ts))
    particle.speed = particle.velocity.mag()
    particle.direction = particle.velocity.toUnitVector()
  
  # Update object properties in this frame
  updateObjects = (ts) ->
    # determine which simulation to run
    if sim == 'force'
      # calculate force on endpoint
      f = spring.forceOnEndpoint()
      
      if (f == Spring.BOUNCE)
        console.log("BOUNCE")
        forceOnEnd = "BOUNCE"
      else
        forceOnEnd = f.inspect()
      queueOutput "force at endpoint: #{forceOnEnd}"
      
      #for o in objects
        # updateParticleFromSprings 
    else if sim == 'particle'
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
    else if sim == 'dhm'
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

    queueOutput "spring length: #{spring.currentLength()}" if spring?
    
    # adjust spring length and endpoint velocity based on force value
  # animate all objects
  update = ->
    # Pass latest timestep to the collision detection function
    timeNow = (new Date()).getTime()
    if lastTime != 0
      elapsed = (timeNow - lastTime) / 1000
      elapsed = 0.1 if elapsed > 0.1
      drawableText = []
      checkCollisions()
      updateObjects(elapsed)
      
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
  