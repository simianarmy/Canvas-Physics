# canvasEvents.js.coffee
#
# Event handler functions for common canvas-related events

canvasEvents = (canvas) ->
  # mouse coordinates to canvas coordinates
  convertEventToCanvas = (evt) ->
    # get canvas position
    obj = canvas
    top = left = 0

    while obj.tagName != 'BODY'
      top += obj.offsetTop
      left += obj.offsetLeft
      obj = obj.offsetParent

    # return relative mouse position
    mouseX = evt.clientX - left + window.pageXOffset
    mouseY = evt.clientY - top + window.pageYOffset
    p = {
      x: mouseX
      y: mouseY
    }

  # mouse event handlers
  mouseDown = (evt) ->
    convertEventToCanvas evt
    
  mouseUp = (evt) ->
    dragging = false
    
  mouseMove = (evt) ->
    convertEventToCanvas evt
  
  # return public functions
  {mouseDown, mouseUp, mouseMove}
  
root = exports ? window
root.canvasEvents = canvasEvents