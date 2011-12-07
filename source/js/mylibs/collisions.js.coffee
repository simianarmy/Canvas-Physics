# collision resolution functions

#= require ../libs/sylvester

collisions = ->
  # constants
  collisions.NONE     = -1
  collisions.EMBEDDED = -2
  
  # intersectionTime
  # 
  # @param {Vector} p1 - point1
  # @param {Vector} v1 - point1 displacement
  # @param {Vector} p2 - point2
  # @param {Vector} v2 - point2 displacement
  # @returns {Number} time of intersection
  intersectionTime = (p1, v1, p2, v2) ->
    tc1 = v1.e(1)
    tc2 = v1.e(2)
    sc1 = v2.e(1)
    sc2 = v2.e(2)
    con1 = p2.e(1) - p1.e(1)
    con2 = p2.e(2) - p1.e(2)
    det = tc2 * sc1 - tc1 * sc2
    return 0 if det is 0
    
    con = sc1 * con2 - sc2 * con1
    con / det
    
  circleCircleCollision = (c1, c2) ->
    w = c1.pos.subtract(c2.pos)
    r = c1.radius + c2.radius
    ww = w.dot(w)
    if w < Math.pow(r, 2)
      console.log "EMBEDDED"
      return collisions.EMBEDDED
    
    v = c1.displacement.subtract(c2.displacement)
    a = v.dot(v)
    b = w.dot(v)
    c = ww - Math.pow(r, 2)
    root = Math.pow(b, 2) - a * c
    return collisions.NONE if root < 0
    
    t = (-b - Math.sqrt(root)) / a
    return collisions.NONE unless isImpendingCollision t
    
    collisionNormal = w.add(v.x(t))
    collisionNormal.toUnitVector()
    [t, collisionNormal]
    
  # circleWallCollision
  # Detect collision between circle and wall
  #
  # @returns {Array}
  #   0: {Number} time to collision
  #   1: {Vector} collision normal
  circleWallCollision = (c, wall) ->
    #console.log "circleWallCollision circle: " + c.pos.inspect()
    t = collisions.NONE
    collisionNormal = null
    n = wall.vec.normal().toUnitVector()
    oa = wall.pos.subtract(c.pos)
    an = oa.dot(n)
    
    if (Math.abs(an) < c.radius)
      console.log "EMBEDDED"
      return collisions.EMBEDDED
    
    r = null
    v = 0
    if an < 0
      r = n.x(-c.radius)
      v = c.displacement.dot(n)
    else
      r = n.x(c.radius)
      v = c.displacement.dot(n.x(-1))
    
    collisionNormal = r.x(-1)
    
    if v > 0 # moving away from wall
      return [t, null]
      
    t = intersectionTime(c.pos.add(r), c.displacement, wall.pos, wall.vec)
    [t, collisionNormal]

  isImpendingCollision = (ts) ->
    0 < ts <= 1
  
  # General purpose collision detection for arbitrary shapes
  # 
  # @param {Shape} s1 - first shape object
  # @param {Shape} s2 - 2nd shape object
  # @returns {Array} 
  #   0: Vector - collisionNormal - set to normal of point of collision if collision is detected
  #   1: Number - time to collision
  #
  detectCollision = (s1, s2) ->
    switch s1.name
      when 'Circle'
        switch s2.name
          when 'Circle'
            circleCircleCollision(s1, s2)
          when 'Line'
            circleWallCollision(s1, s2)
          else
            console.log "Unknown shape: " + s2
      else
        console.log "Unknown shape: " + s1
  
  # resolveCollisionFree

  # Sets velocity of 2 objects with any mass after elastic collision along normal
  # @params: 2 objects and normal of collision
  resolveCollisionFree = (s1, s2, n) ->
    #console.log "resolving collision for " + s1 + ", " + s2
    r = s1.mass / s2.mass
    base = s2.velocity.dup()
    baseIsZero = base.eql Vector.Zero()
    u = null
    # If base has zero velocity and objects are the same type, simply switch velocities
    if baseIsZero
      if (s1.name == s2.name)
        s2.velocity = s1.velocity.dup()
        s1.velocity = Vector.Zero()
        return
      u = s1.velocity.dup() # Sylvester doesn't like subtracting by zero
    else
      u = s1.velocity.subtract(base)
      
    un = u.componentVector(n)
    ut = u.subtract(un)
    vn = un.multiply(r-1).divide(r+1)
    wn = un.multiply(2 * r).divide(r+1)
    ut = ut.add(vn)

    s1.velocity = if baseIsZero then ut else ut.add(base)
    s2.velocity = if baseIsZero then wn else wn.add(base)
  
  # resolveCollision
  #                                                   
  # General purpose collision resolution for arbitrary shapes
  # @param {Shape} s1 - first shape object               
  # @param {Shape} s2 - 2nd shape object              
  # @param {Vector} n - collision normal
  resolveCollision = (s1, s2, n) ->
    resolveCollisionFree s1, s2, n
 
  # Collision detection+resolution on all scene objects
  # Side effects: moves objects and changes their velocity based  on 
  # any collision interactions
  #
  # @param {Number} timestep since last call
  # @param {Array} moving objects
  # @param {Array} fixed objects
  checkCollisions = (ts, moving, fixed) ->
    #console.log "checkCollisions " + ts
    mn = 2
    ob1 = ob2 = null
    n = Vector.Zero(3)
    collisionNormal = null
    collisionTime = 0
    
    displacement = (ts, vel) ->
      vel.x(ts / 1000.0)
      
    # Moves some shape for some timestep
    #
    # @param {Shape} s - object to move
    # @param {Number} ts - timestep
    moveObject = (s, ts) ->
      s.move displacement(ts, s.velocity)
    
    detectCollisionHelper = (s1, s2) ->
      s1.displacement = displacement(ts, s1.velocity)
      s2.displacement = displacement(ts, s2.velocity)
      
      [collisionTime, collisionNormal] = detectCollision s1, s2
      
      return unless isImpendingCollision(collisionTime)
      #console.log "collision in " + collisionTime
      
      m = Math.min(mn, collisionTime)
      # If collision is most imminent, save objects' info
      if m < mn
        mn = m
        n = collisionNormal.dup()
        ob1 = s1
        ob2 = s2
        
    for i in [(moving.length-1)..0]
      for j in [(i-1)..0]
        detectCollisionHelper(moving[i], moving[j]) if j >= 0
      
      #now search for collisions with fixed objects
      for j in [(fixed.length-1)..0]
        detectCollisionHelper(moving[i], fixed[j]) if j >= 0
    
    # Move objects
    tmove = if (mn == 2) then ts else (mn * ts)

    if tmove > Sylvester.precision
      moveObject(obj, tmove) for obj in moving
    
    # if there is no collision we are finished
    return if mn == 2
    
    # resolve collisions
    resolveCollision ob1, ob2, n
    
    # recurse for the next timestep portion
    nextts = ts * (1 - mn)
    checkCollisions(nextts, moving, fixed) if nextts > Sylvester.precision
  
  # Return public functions
  {checkCollisions}
  
root = exports ? window
root.collisions = collisions()