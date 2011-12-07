# main()

#= require mylibs/scene

$(document).ready ->
  sc = scene()
  sc.setup()

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