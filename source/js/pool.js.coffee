# pool.js.coffee

#= require ./mylibs/PoolTable
#= require ./mylibs/canvasEvents

MAX_CUE_TIME        = 2
MAX_BALL_SPEED      = 130

$(document).ready ->
  shooting = false
  shotForce = 0
  shotTimerID = null
  cueStart = 0
  currentPlayer = 1
  player1Color = player2Color = null
  winner = null
  collisionSound = null
  
  # fetch and save the canvas context
  $canvas = $("#poolcanvas")
  canvas = $canvas.get(0)
  context = canvas.getContext('2d')  
  
  loadAudio = ->
    collisionSound = $('#ballcollisionSound')[0]
    newGame()
    
  incShotForce = ->
    timeNow = new Date().getTime()
    if cueStart != 0
      shotForce = timeNow - cueStart
      
    shoot() if shotForce/1000 >= MAX_CUE_TIME
  
  shoot = ->
    clearInterval shotTimerID
    cueSpeed = (shotForce / 500) * MAX_BALL_SPEED
    sc.makeShot currentPlayer, cueSpeed
    endShot()
    
  startShot = ->
    shotForce = 0
    cueStart = new Date().getTime()
    shotTimerID = setInterval(incShotForce, 100)
    shooting = true
    
  endShot = ->
    shooting = false
    shotForce = 0
  
  playerTurnFinished = (playerInfo) ->
    if !player1Color && playerInfo[currentPlayer]
      player1Color = playerInfo[currentPlayer]
      $('.hud #p'+currentPlayer).append('&nbsp;&nbsp'+player1Color+'s')
      op = sc.otherPlayer(currentPlayer)
      player2Color = playerInfo[op]
      $('.hud #p'+op).append('&nbsp;&nbsp'+playerInfo[op]+'s')
    
    if sc.isGameOver()
      endGame sc.getWinner()
    else
      switchPlayer()
    
  onCollision = (collisionSpeed) ->
    volume = Math.min(collisionSpeed / MAX_BALL_SPEED, 1)
    console.log "playing collision audio volume #{volume}"
    collisionSound.volume = volume
    collisionSound.play()
    
  switchPlayer = ->
    currentPlayer = if currentPlayer == 1 then 2 else 1
    updateHUD()
    
  resetHUD = ->
    $('.hud #p1').html('Player 1')
    $('.hud #p2').html('Player 2')
    $('.hud span').css('background-color', 'white')
    
  updateHUD = ->
    $('.hud span').css('background-color', 'white')
    $('.hud #p'+currentPlayer).css('background-color', '#00DD00')
    
  mouseMove = (evt) ->
    pnt = cevents.mouseMove(evt)
    sc.updateCue(pnt) unless shooting
      
  mouseDown = (evt) ->
    pnt = cevents.mouseDown(evt)
    unless shooting
      sc.initShot pnt
      startShot()

  mouseUp = (evt) ->
    shoot() if shooting
    shooting = false
  
  keyUp = (evt) ->
    console.log "on key up #{evt.keyCode}"
    return false if shooting
    dir = null
    switch evt.keyCode
      when 37, 65
        dir = 'l'
      when 39, 68
        dir = 'r'
    
    sc.moveCue(dir) if dir?

  newGame = ->
    currentPlayer = 1
    player1Color = player2Color = null
    winner = null
    resetHUD()
    updateHUD()
    sc.newGame()
    $('#newgame').hide()
  
  endGame = (winner) ->
    $('.hud #p'+winner).append('&nbsp; ** WINNER')
    $('#newgame').show()
    
  # main  
  # Create main pool table physics object
  sc = PoolTable(context, {
    width: canvas.width
    height: canvas.height
    tableSize: 300
    onCollision: onCollision
    onEndTurn: playerTurnFinished
  })
  # Load sounds
  loadAudio()
  
  cevents = canvasEvents(canvas)
  canvas.addEventListener('mousedown', mouseDown, false)
  canvas.addEventListener('mouseup', mouseUp, false)
  canvas.addEventListener('mousemove', mouseMove, false)
  $(document).keyup(keyUp)
  
  $('#newgame a').click newGame
  