# balls.js.coffee

#= require mylibs/scene

$(document).ready ->
  # fetch and save the canvas context
  canvas = $("#maincanvas").get(0)
  context = canvas.getContext('2d')
  # translate world for origin at bottom left
  context.scale(1, -1)
  context.translate(0, -canvas.height)
  
  # Draw a circle on the canvas
  drawCircle = (c) ->
    context.fillStyle = c.color
    context.beginPath()
    context.arc(c.x(), c.y(), c.radius, 0, Math.PI*2, true);
    context.closePath();
    context.fill();
    
  clearScene = ->
    context.clearRect 0, 0, canvas.width, canvas.height
    
  sc = scene({
    width: canvas.width,
    height: canvas.height,
    clearFunc: clearScene,
    drawFunc: drawCircle
  })

  $('canvas').click ->
    sc.toggleAnimation()
    if $(this).text() == 'Play'
      $(this).text('Pause')
    else
      $(this).text('Play')
      
  $('#free').click -> sc.toggleCirclesY(true)
  $("input[name='num_balls']").change -> 
    nballs = parseInt $(this).attr('value')
    $('#nballs').text nballs
    sc.updateBallCount nballs