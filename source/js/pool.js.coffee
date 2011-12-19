# pool.js.coffee

#= require ./mylibs/PoolTable

$(document).ready ->
  # fetch and save the canvas context
  canvas = $("#poolcanvas").get(0)
  context = canvas.getContext('2d')  
    
  sc = PoolTable(context, {
    width: canvas.width
    height: canvas.height
    tableSize: canvas.height / 2 - 100
  })

  $('canvas').click ->
