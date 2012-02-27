# springs.js
# 
# main() for the springs page demos

#= require ./plugins
#= require mylibs/vec
#= require mylibs/Math
#= require mylibs/Array
#= require mylibs/Line
#= require mylibs/Circle
#= require mylibs/Rectangle
#= require mylibs/Canvas
  
$(document).ready ->
  canvas = new Canvas($("#maincanvas").get(0))
  canvas.setOrigin('bottomleft')
  elapsed = lastTime = 0