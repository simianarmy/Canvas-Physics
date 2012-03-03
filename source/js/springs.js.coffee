# springs.js
# 
# main() for the springs page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Math
#= require mylibs/Spring
#= require mylibs/Circle
#= require mylibs/Canvas
  
$(document).ready ->
  canvas = new Canvas($("#maincanvas").get(0))
  canvas.setOrigin('bottomleft')
  elapsed = lastTime = 0
  paused = true
  springLen = 0
  springMinLen = 0
  springElasticity = 0
  springDamping = 0
  elasticLimit = 0
  compressiveness = 0
  forceOnEnd = Vector.Zero()
  objects = []
  spring = null
  
  # Collect control values
  updateControls = ->
    springLen = parseInt $('input[name=springLen]').val()
    springMinLen = parseInt $('input[name=springMinLen]').val()
    springElasticity = parseFloat $('input[name=springElasticity]').val()
    springDamping = parseFloat $('input[name=springDamping]').val()
    elasticLimit = parseInt Math.max($('input[name=elasticLimit]').val(), springLen)
    compressiveness = parseInt $('input[name=compressiveness]').val()
    
    # Display updated values next to sliders
    $('#springLen').html(springLen)
    $('#springMinLen').html(springMinLen)
    $('#springElasticity').html(springElasticity)
    $('#springDamping').html(springDamping)
    $('#elasticLimit').html(elasticLimit)
    
  # update spring properties (from controls)
  updateSpring = (spring) ->
    spring.elasticity = springElasticity
    spring.damping = springDamping
    spring.compressiveness = if compressiveness == Spring.LOOSE then Spring.LOOSE else Spring.RIGID
    spring.minLength = springMinLen
    spring.elasticLimit = elasticLimit
  
  # Force on particle due to spring simulation
  forceFromStringSim = ->
    console.log "init force from spring simulation"
    # Create spring & particle to attach to an endpoint
    # Fix spring end to bottom center
    spring = new Spring($V([canvas.width/2, 0, 0]), $V([0, springLen, 0]), 
      $V([0, 0, 0]), 
      $V([0, 10, 0]),
      springLen)
    updateSpring(spring)
    
    # Create particle at end of spring
    #particle = new Circle(canvas.width/2, springLen, 0, { radius: 5 })
    
    objects = [spring]
  
  # Draw objects on canvas
  drawScene = (objects, ts) ->
    canvas.clear()
    canvas.drawText("force at endpoint: #{forceOnEnd.inspect()}", canvas.width/2, 50)
    
    for obj in objects
      switch obj.name
        when 'Circle'
          canvas.inContext ->
            canvas.drawCircle obj

        when 'Spring'
          canvas.drawLine obj
          
  # Update object properties in this frame
  updateObjects = (ts) ->
    # calculate force on endpoint
    forceOnEnd = spring.forceOnEndpoint()
    if (forceOnEnd == Spring.BOUNCE)
      console.log("BOUNCE")
      
    # adjust spring length and endpoint velocity based on force value
  # animate all objects
  update = ->
    # Pass latest timestep to the collision detection function
    timeNow = new Date().getTime()
    if lastTime != 0
      elapsed = (timeNow - lastTime) / 1000
      elapsed = 0.1 if elapsed > 0.1
      updateObjects(elapsed)
      
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
      
  $('.forceFromSpring').click(forceFromStringSim);

  # Update simulation controls
  $('#controls input').change(updateControls);
    
  updateControls()
  tick()
  