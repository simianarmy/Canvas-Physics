# collision resolution functions

#= require ../libs/sylvester

collisions = {}
collisions = (->
  # constants
  collisions.NONE     = -1
  collisions.EMBEDDED = -2
  
  # intersection
  # Finds the point where 2 lines AB and CD intersect
  # @returns {Number} time 
  intersection = (a, b, c, d) ->
    tc1 = b.e(1) - a.e(1)
    tc2 = b.e(2) - a.e(2)
    sc1 = c.e(1) - d.e(1)
    sc2 = c.e(2) - d.e(2)
    con1 = c.e(1) - a.e(1)
    con2 = c.e(2) - a.e(2)
    det = tc2 * sc1 - tc1 * sc2
    return 0 if det is 0
    con = tc2 * con1 - tc1 * con2
    s = con / det
    return false if s < 0 or s > 1
    if tc1 != 0
      (con1 - s * sc1) / tc1
    else
      (con2 - s * sc2) / tc2
    
  
  # intersectionTime  
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
    
  # circleCircleCollision
  # Detect collision between 2 circles  
  # @returns {Array}  
  #   0: {Number} time to collision  
  #   1: {Vector} collision normal
  circleCircleCollision = (c1, c2) ->
    w = c1.pos.subtract(c2.pos)
    r = c1.radius + c2.radius
    ww = w.dot(w)
    if (ww+Sylvester.precision) < (r*r)
      console.log "CIRCLE EMBEDDED"
      return collisions.EMBEDDED
    
    v = c1.displacement.subtract(c2.displacement)
    a = v.dot(v)
    b = w.dot(v)
    c = ww - Math.pow(r, 2)
    root = Math.pow(b, 2) - a * c
    return collisions.NONE if root < 0
    
    t = (-b - Math.sqrt(root)) / a
    return collisions.NONE unless isImpendingCollision t
    
    collisionNormal = w.add(v.x(t)).toUnitVector()
    [t, collisionNormal]
    
  # circleWallCollision  
  # Detect collision between circle and wall  
  # @returns {Array}  
  #   0: {Number} time to collision  
  #   1: {Vector} collision normal  
  circleWallCollision = (c, wall) ->
    t = collisions.NONE
    collisionNormal = null
    n = wall.vec.normal().toUnitVector()
    oa = wall.pos.subtract(c.pos)
    an = oa.dot(n)
    
    if (Math.abs(an) < c.radius)
      console.log "WALL EMBEDDED"
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

  # Check for collision between rotating line and circle
  # Anglular values should be in radians
  # @param {Number} theta0 angle of starting position of line from the vertical
  # @param {Number} omega angular velocity of rotating line
  # @param {Number} l line length 
  # @param {Number} r ball radius
  # @param {Number} d distance of line origin to ball center
  # @param {Number} alpha angle of vertical and line to ball center 
  angularCollisionLineCircle = (theta0, omega, l, r, d, alpha) ->
    return collisison.NONE if d > l + r
    return collisions.EMBEDDED if d < r
    k = 1
    # move into a  calculation within the range of [0,2pi]
    alpha -= theta0
    if omega < 0
      omega = -omega
      alpha = -alpha
      k = -1
    
    pi2 = Math.PI * 2
    while alpha < 0
      alpha += pi2
    while alpha > pi2
      alpha -= pi2
    
    # check if there is a possible collision
    return collisions.NONE if alpha > omega
    
    # now perform the appropriate collision check
    if d*d <= (l*l + r*r)
      (alpha - k * Math.asin(r / d)) / omega
    else
      (alpha - k * Math.acos((l*l + d*d - r*r) / (2*l*d))) / omega
      
  isImpendingCollision = (ts) ->
    0 < ts <= 1
  
  # General purpose collision detection for arbitrary shapes  
  # @param {Shape} s1 - first shape object  
  # @param {Shape} s2 - 2nd shape object  
  # @returns {Array}  
  #   0: {Number} time to collision  
  #   1: {Vector} collision normal
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
  
  # resolveInelasticCollisionFree
  #
  # Sets velocity of 2 objects with any mass after inelastic collision along normal  
  # @params: 2 objects and normal of collision
  resolveInelasticCollisionFree = (s1, s2, n) ->
    r = s1.mass / s2.mass
    u = ob1.velocity.subtract(s2.velocity)
    e = ob1.efficiency * ob2.efficiency
    un = u.component(n)
    ut = u.subtract(un).x(n).mag()
    sq = r*r * un*un - (r+1) * ((r-e) * un*un + (1-e) * ut*ut)
    vn = n.x(Math.sqrt(sq) - r*un).div(r+1)
    wn = (n.x(un).subtract(vn)).x(r)
    s1.velocity = s2.velocity.add(vn.add(ut))
    s2.velocity = wn.add(s2.velocity)
    
  # resolveInelasticCollisionFixed
  #
  # Sets velocity of 2 objects with equal mass after inelastic collision along normal  
  # @params: 2 objects, normal of collision
  resolveInelasticCollisionFixed = (s1, s2, n) ->
    e = s1.efficiency * s2.efficiency
    un = s1.velocity.componentVector(n)
    ut = s1.velocity.subtract(un)
    sq = Math.sqrt(e)
    vn = un.x(-1).x(sq)
    s1.velocity = ut.add(vn)
      
  # resolveCollisionEqualMass
  #
  # Sets velocity of 2 objects with equal mass after elastic collision along normal  
  # @params: 2 objects and normal of collision  
  resolveCollisionEqualMass = (s1, s2, n) ->
    u = s1.velocity.subtract(s2.velocity)
    un = u.componentVector(n)
    ut = u.subtract(un)
    s1.velocity = ut.add(s2.velocity)
    s2.velocity = un.add(s2.velocity)
    
  # resolveCollisionFree  
  #
  # Sets velocity of 2 objects with any mass after elastic collision along normal  
  # @params: 2 objects and normal of collision  
  resolveCollisionFree = (s1, s2, n) ->
    r = s1.mass / s2.mass
    base = s2.velocity.dup()
    baseIsZero = base.eql Vector.Zero(3)
    u = null

    # If base has zero velocity and objects are the same type, simply switch velocities
    if baseIsZero
      if (s1.name == s2.name)
        s2.velocity = s1.velocity.dup()
        s1.velocity = Vector.Zero(3)
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
    if s1.mass == s2.mass
      resolveCollisionEqualMass s1, s2, n
    else
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
        s1.collided = s2.collided = true
        
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
  
  # determine if a point lies inside a triangle
  # using alg. from http://www.blackpawn.com/texts/pointinpoly/default.html
  pointInTriangle = (pt, triangle) ->
    #console.log "pointInTriangle pnt #{pt.inspect()}"
    #console.log "triangle: #{triangle.toString()}"
    sameSide = (p1, p2, a, b) ->
      cp1 = b.subtract(a).cross(p1.subtract(a))
      cp2 = b.subtract(a).cross(p2.subtract(a))
      cp1.dot(cp2) >= 0
    
    [a, b, c] = triangle.points
    sameSide(pt, a, b, c) and sameSide(pt, b, a, c) and sameSide(pt, c, a, b)
  
  pointInPolygon = (pt, poly) ->
    # Use faster pointInTriangle test if possible
    return pointInTriangle(pt, poly) if poly.points.length == 3
    
    # choose an arbitrary point outside the polygon
    # set mx to the max x-value in poly
    vxs = (v.e(1) for v in poly.points)
    mx = Math.max vxs...
    outpoint = $V([mx + 10, 0, 0])
    
    # add beginning point to end for the last line segment
    poly.points.push(poly.points[0])
    # now count the intersections along the ray from pt to outpoint
    intersections = 0
    c = poly.points.length
    for i in [0...c-1]
      p1 = poly.points[i]
      p2 = poly.points[(i%c)+1]
      throw "error in pointInPolygon for index #{i}" unless p1? and p2?
      t = intersection(p1, p2, pt, outpoint)
      if isImpendingCollision(t)
        #console.log "intersection in #{t} for #{pt.inspect()} in #{p1.inspect()} #{p2.inspect()}"
        intersections += 1
    
    # if number of intersections is odd, then point is inside polygon 
    (intersections % 2) == 1

  # Return public functions
  {checkCollisions, 
  detectCollision, 
  isImpendingCollision,
  resolveCollision,
  resolveInelasticCollisionFixed,
  angularCollisionLineCircle,
  pointInTriangle, 
  pointInPolygon}
)()

root = exports ? window
root.collisions = collisions