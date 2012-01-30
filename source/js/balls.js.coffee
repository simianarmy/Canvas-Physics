# balls.js.coffee

#= require mylibs/circles_scene
#= require mylibs/Canvas

$(document).ready ->
  # fetch and save the canvas context
  canvas = new Canvas($("#maincanvas").get(0), '2d')
  canvas.setOrigin('topleft')
    
  clearScene = ->
    canvas.clear()
    
  drawScene = (c) ->
    canvas.drawCircle(c)
  
  sc = scene({
    width: canvas.width
    height: canvas.height
    clearFunc: clearScene
    drawFunc: drawScene
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