# main()

#= require ./mylibs/scene
#= require ./mylibs/vec

$(document).ready ->
  box = $('#ballbox')
  bw = box.width()
  bh = box.height()
  canvas = Raphael('ballbox', bw, bh);
  
  # Draw a circle on the page
  drawCircle = (c) ->
    # Create svg object if necessary
    if c.svg?
      c.svg.attr({cx: c.x(), cy: c.y()})
      if c.collided
        c.svg.attr({fill: sc.randomCircleColor()})
        c.collided = false
    else
      c.svg = canvas.circle(c.x(), c.y(), c.radius).attr({
        fill: c.color, 
        stroke: '#000', 
        'stroke-width': 2
      })
      c.svg.mouseover -> 
        c.velocity.elements[0] = -c.velocity.e(1)
        c.velocity.elements[1] = -c.velocity.e(2)
      
  sc = scene({width: bw, height: bh, drawFunc: drawCircle})
  
  $('#ballbox').click ->
    sc.toggleAnimation()
      
  $('#free').click -> sc.toggleCirclesY(true)
  $("input[name='num_balls']").change -> 
    nballs = parseInt $(this).attr('value')
    $('#nballs').text nballs
    sc.updateBallCount nballs