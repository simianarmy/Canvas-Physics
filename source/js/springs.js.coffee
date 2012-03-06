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
  gravity = 5
  energy = null
  forceOnEnd = Vector.Zero()
  # objects 
  objects = []
  drawableText = []
  spring = null
  particle = null
  # mouse throwing variables
  mouseOnBall = false
  lastDragPoint = null
  
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
    spring.compressiveness = if compressiveness == 'loose' then Spring.LOOSE else Spring.RIGID
    spring.minLength = springMinLen
    spring.elasticLimit = elasticLimit

  updateParticle = (p) ->
    p.mass = particleMass
    p.radius = Math.max(particleMass / 5, 1)
    
  # move spring endpoint up or down
  moveSpringEnd = (dir) ->
    if dir == 'u'
      spring.pnt2 = spring.pnt2.add($V([0, 5, 0]))
    else
      spring.pnt2 = spring.pnt2.subtract($V([0, 5, 0]))
      
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
    spring = new Spring($V([canvas.width/2, canvas.height, 0]), $V([0, -springLen, 0]), 
      $V([0, 0, 0]), 
      $V([0, 10, 0]),
      springLen)
    updateSpring spring
    
    particle = new Circle(canvas.width/2, canvas.height-springLen, 0, {
      radius: particleMass/5,
      color: 'black',
      mass: particleMass,
      speed: 0,
      direction: $V([0, -1, 0])
    })
    objects = [spring, particle]
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
    drawableText.push txt
    
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
      
    else if sim == 'particle'
      # calculate new particle properties
      next = particles.particleOnSpring(spring, particle, energy, ts, gravity)
      
      queueOutput "new pos: #{next.pos.inspect()}"
      queueOutput "new speed: #{next.speed}"
      queueOutput "new energy: #{next.totalEnergy}"
      
      spring.pnt2 = next.pos.dup()
      particle.pos = next.pos.dup()
      particle.speed = next.speed
      
      if next.speed > 0
        queueOutput "new velocity: #{next.velocity.inspect()}"
        particle.direction = next.velocity.dup()
      else
        # get force on particle from spring
        f = spring.forceOnEndpoint()
        particle.speed = f.mag()
        particle.direction = f.toUnitVector()
        
      energy = next.totalEnergy
      
    queueOutput "spring length: #{spring.currentLength()}"
    
  # Initiate user 'throw' of a particle on spring
  # @param {Vector} v vector of throw
  throwBall = (v) ->
    console.log "throwing ball #{v.inspect()}"
    particle.speed = v.mag()
    particle.direction = v.toUnitVector()
    paused = false
    
    # adjust spring length and endpoint velocity based on force value
  # animate all objects
  update = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = (timeNow - lastTime) / 1000
      elapsed = 0.1 if elapsed > 0.1
      drawableText = []
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
      lastDragPoint = p
    
  mouseUp = (evt) ->
    p = events.convertEventToCanvas(evt)
    if mouseOnBall
      # save throwing velocity
      console.log "last pos", lastDragPoint
      console.log "pos now", p
      throwBall pointToVec(p).subtract(pointToVec(lastDragPoint))
    mouseOnBall = false
      
  mouseMove = (evt) ->
    if mouseOnBall
      lastDragPoint = events.convertEventToCanvas(evt)
      particle.pos = pointToVec(lastDragPoint)
      spring.pnt2 = particle.pos
      
  $('.forceFromSpring').click(forceFromStringSim);
  $('.particleOnSpring').click(particleOnStringSim);
  
  # Update simulation controls
  $('#controls input').change(updateControls);
  
  $('#info span').hide()
  $(document).keydown(keyDown)
  $canvas.mousedown(mouseDown)
  $canvas.mouseup(mouseUp)
  $canvas.mousemove(mouseMove)
  
  updateControls()
  tick()
  