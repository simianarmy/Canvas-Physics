# collision resolution functions

#= require ../libs/sylvester

collisions = (->  
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
      return [collisions.EMBEDDED, n]
    
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

  # Detect collision between rotating line and circle
  # Anglular values must be in radians
  # @param {Number} theta0 angle of starting position of line from the vertical
  # @param {Number} omega angular velocity of rotating line
  # @param {Number} l line length 
  # @param {Number} r ball radius
  # @param {Number} d distance of line origin to ball center
  # @param {Number} alpha angle of vertical and line to ball center 
  # @param {Number} perpDist perpendicular distance of line from center of rotation
  # @return {Number} NONE or EMBEDDED or time to collision (if < 1)
  angularCollisionLineCircle = (theta0, omega, l, r, d, alpha, perpDist) ->
    return collisison.NONE if d > l + r
    return collisions.EMBEDDED if d < r
    # k = 1 for clockwise motion, -1 otherwise
    k = 1
    # move into a  calculation within the range of [0,2pi]
    alpha -= theta0
    if omega < 0
      omega = -omega
      alpha = -alpha
      k = -1
    
    alpha = Math.radRangeAngle(alpha, 0)
    
    # check if there is a possible collision.
    # this means any collision in t > 1 will not be considered.
    return collisions.NONE if alpha > omega
    
    # now perform the appropriate collision check
    if d*d <= (l*l + r*r)
      (alpha - k * Math.asin((r-perpDist) / d)) / omega
    else
      (alpha - k * Math.acos((l*l + d*d - r*r) / (2*l*d))) / omega
      
  # Detect collision between rotating line and moving or stationary circle.
  # This method is quite different than angularCollisionLineCircle() which only 
  # deals with stationary circles.
  # From the MPFP CDROM collision simulation Director code.  
  # TODO: Support for cases where the rotating line is offset from its rotating point.
  # @param {Line} line shape
  # @param {Circle} circle shape
  # @param {Number} ts current timestep
  # @return {Object} 
  #   t: 0 if collision detected, collisions.NONE if not
  #   moment1: no idea
  #   moment2: no idea
  angularCollisionLineCircle2 = (line, circle, ts) ->
    # determine start and end positions
    startPos = circle.pos.subtract(line.pos)
    endPos = circle.locationAfter(ts).subtract(line.locationAfter(ts))
    
    # FIXME: HAVING TO USE 90 DEGREE OFFSET SEEMS WRONG HERE!!
    lineStartAng = Math.degreesToRadians(90-line.rotation)
    lineAngDisp = line.angularVelocity('r') * ts
    lineEndAng = lineStartAng + lineAngDisp

    console.log("ball pos: #{startPos.inspect()} - #{endPos.inspect()}")
    console.log("line angles: #{lineStartAng} - #{lineEndAng}")
    
    n1 = Vector.directionVector(lineStartAng + Math.PI/2)
    n2 = Vector.directionVector(lineEndAng + Math.PI/2)
    
    # point n1 and n2 towards the initial position of the circle
    startDist = n1.dot(startPos)
    if startDist < 0
      n1 = n1.x(-1)
      n2 = n2.x(-2)
      startDist = -startDist

    noColl = {t: collisions.NONE}
    r = circle.radius

    # NOTE:
    # Equation can't be solved algebraically - an approximation method must be used
    # Save time by checking whether it's possible for the 2 objects to collide at all
    
    # 1. Check if circle intersects the complete circle swept out by the line
    unless (startDist - r) * (n2.dot(endPos) - r) < 0
      return noColl
      
    # 2. Check if angle swept out by the circle during the time interval 
    # overlaps with the angle swept out by the line.
    if ((startPos.subtract(n1.x(r)).mag() <= line.length) ||
      (endPos.subtract(n2.x(r)).mag() <= line.length))
        return {t: 0,
        normal: n1.x(-1),
        moment1: $V([0, 0, 0]),
        moment2: startPos.subtract(n1.x(r)),
        ref1: circle,
        ref2: line
        }

    # otherwise, check for intersection with line endpoints
    # TODO:
    noColl
  
  # Detect collision between rotating line and stationary line
  # @param {Number} theta0 angle of starting position of line from the vertical
  # @param {Number} omega angular velocity of rotating line
  # @param {Line} line1 rotating line object
  # @param {Line} line2 stationary line object 
  # @param {Boolean} segment flag: true=checking for endpoints, false=continuous wall
  # @return {Number} time to collision or NONE
  angularCollisionLineStationaryLine = (theta0, omega, rline, sline, segment) ->
    # Make rotating line pos the origin
    spos = sline.pos.subtract(rline.pos)
    l = rline.length
    n = sline.vec.normal().toUnitVector()
    d = spos.dot(n)
    
    if d < 0
      d = -d
      n = n.x(-1)
    # so n is the normal vector directed towards the point where the perp. from 
    # the rotating line position meets the stationary line (N)
    if d > rline.length # too far from wall
      console.log("#{d} > #{rline.length} - too far from wall!")
      return collisions.NONE
    
    endpt = null
    # if checking for endpoints, see if they are relevant
    if segment
      pn = n.x(d) # vector = rotating line origin P to N
      dd = l*l - d*d # squared length TD
      if omega > 0
        if !Vector.isClockwise(spos, sline.vec)
          endpt = spos.dup() #  stationary line point
        else
          endpt = spos.add(sline.vec) # endpoint of stationary line
      else
        if !Vector.isClockwise(spos, sline.vec)
          endpt = spos.add(sline.vec)
        else
          endpt = spos.dup()

      d1 = Math.pow(endpt.subtract(pn).mag(), 2)
      if d1 < dd # there is a potential collision with the endpoint
        # a is the angle of collision with the endpoint
        a = Math.acos(d / endpt.mag())
        if !Vector.isClockwise(endpt, pn.subtract(endpt))
          a = -a
      else
        a = Math.acos(d / l)
        if omega > 0
          a = -a
        # check if this collision occurs outside the line segment
        # ADDING SCALAR TO VECTOR??? WTF DUDE??
        # BOOK CODE: pn + Math.abs(a) * Math.sqrt(dd) / a
        # TRYING MULTIPLY INSTEAD...SHEESH
        ap = pn.x(Math.abs(a) * Math.sqrt(dd) / a)
        # note that abs(a)/a is 1 if a>0, -1 otherwise
        k = ap.subtract(spos).mag() / sline.vec.mag()
        return collisions.NONE if k > 1 || k < 0
    # end if segment
    else
      # check for collision with an infinite wall
      a = Math.acos(d / l)
      if omega > 0
        a = -a
          
    tn = n.angleOf()
    someangle = tn - theta0 + a

    # Move angle to range [1, 2pi) doesn't work, need to use range [0, 2pi)..
    # what about -pi,pi??
    ranged = Math.radRangeAngle(someangle, 0)
    t = ranged / omega
    
    console.log("n: #{n.inspect()}")
    console.log("angle of n: #{tn}")
    console.log("theta0: #{theta0}")
    console.log("alpha: #{a}")
    console.log("total angle: #{someangle}")
    console.log("ranged: #{ranged}")
    console.log("collision if ranged <= #{omega}")    
    console.log("t: #{t}")

    return collisions.NONE if t <= 0 || t > 1
    
    # If collision on flat, we must make sure the collision is with the line
    if !segment
      # We need vector AT!
      # Get point PT
      pt = Vector.unitVector(Math.radRangeAngle(a+tn)).x(rline.length)
      console.log("pt: #{pt.inspect()}")
      oga = spos.dup()
      vec = sline.vec.dup()
      if omega > 0
        if Vector.isClockwise(spos, sline.vec)
          oga = spos.add(sline.vec)
          vec = vec.x(-1)
      else
        # TODO: FIGURE OUT FOR omega <= 0
      
      at = pt.subtract(oga)
      atv = at.dot(vec)
      vmag2 = Math.pow(sline.vec.mag(), 2)
      console.log("at: #{at.inspect()}, atv: #{atv}, |v|sq = #{vmag2}")

      if atv < 0 || atv > vmag2
        console.log("collision not on line!")
        return collisions.NONE 
      
    t
    
  # Detect collision between 2 rotating lines
  # @param {Line} l1 first line
  # @param {Line} l2 second line
  # @param {Number} ts timestep
  # @return {Number} time to collision or NONE
  angularCollisionLineLine = (l1, l2, ts) ->
    angleAfterTimestep = (line) ->
      line.radRotation() + line.angularVelocity('r') * ts
    
    # check for potential collision triangle in this timestep
    theta0 = l1.radRotation()
    phi0 = l2.radRotation()
    
    k0 = phi0 - theta0
    k1 = phi0 - theta0 + (l2.angularVelocity('r') - l1.angularVelocity('r'))
    unless (Math.PI <= k0 <= Math.PI*2) || (Math.PI <= k1 <= Math.PI*2)
      return collisions.NONE 
    
    # if triangle is formed correctly, use approximation and sine rule
    # get angles of the new triangle
    pq = l2.pos.subtract(l1.pos)
    pqu = pq.toUnitVector()
    d = pq.mag()
    
    l1v = Vector.unitVector(angleAfterTimestep(l1))
    l2v = Vector.unitVector(angleAfterTimestep(l2))
    
    l1vAngle = Math.acos(l1v.dot(pqu))
    l2vAngle = Math.acos(l2v.dot(pqu.x(-1)))
    beta = Math.radRangeAngle(Math.PI - l1vAngle - l2vAngle, 0)
    precision = 0.00005
    console.log("beta: #{beta}, d: #{d}")
    # Need length PR or QR calculated from triangle
    # Use law of cosines for each side
    l2len = Math.sqrt(d*d + l1.length*l1.length - 2*d*l1.length*Math.cos(l1vAngle))
    d1 = (Math.sin(beta) / l1.length) - (Math.sin(l2vAngle) / d)
    d2 = (Math.sin(beta) / l2len) - (Math.sin(l1vAngle) / d)
    console.log "d1: #{d1} d2: #{d2}"
    if (Math.abs(d1) <= precision) || (Math.abs(d2) <= precision)
      console.log "equality found: #{d1}"
      return {t: 0}
    
    l1len = Math.sqrt(d*d + l2.length*l2.length - 2*d*l2.length*Math.cos(l2vAngle))
    d1 = (Math.sin(beta) / l1len) - (Math.sin(l2vAngle) / d)
    d2 = (Math.sin(beta) / l2.length) - (Math.sin(l1vAngle) / d)
    console.log "d1: #{d1} d2: #{d2}"
    if (Math.abs(d1) <= precision) || (Math.abs(d2) <= precision)
      console.log "equality found: #{d1}"
      return {t: 0}
        
    collisions.NONE
    
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
      
  # resolveCollisionFixed
  #
  # Sets velocity of an object after an elastic collision along normal
  # @param {Shape} ob colliding object
  # @param {Vector} n collision along vector
  resolveCollisionFixed = (ob, n) ->
    u = ob.velocity
    ob.setVelocity u.subtract(u.componentVector(n).x(2))
    
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
  
  # resolveAngularCollision
  #
  # Sets velocity and angular velocities after elastic collision
  # @param {Shape} s1 first object
  # @param {Shape} s2 other object
  # @param {Vector} n normal of collision
  # @param {Vector} mom1 moment vector for s1 
  #   mom = clockwise normal of the radius vector
  # @param {Vectory} mom2 moment vector for s2
  resolveAngularCollision = (s1, s2, n, mom1, mom2) ->
    u1 = s1.velocity
    u2 = s2.velocity
    om1 = s1.angularVelocity('r')
    om2 = s2.angularVelocity('r')
    
    J = 2 * u2.subtract(u1).add(mom2.x(om2)).subtract(mom1.x(om1)).dot(n)
    denom = 0
    if !s1.isFixedLinear()
      m1 = s1.mass
      denom += 1 / m1
    if !s2.isFixedLinear()
      m2 = s2.mass
      denom += 1 / m2
    if !s1.isFixedAngular()
      moi1 = s1.MOI()
      dp1 = mom1.dot(n)
      denom += (dp1*dp1 / moi1)
    if !s2.isFixedAngular()
      moi2 = s2.MOI()
      dp2 = mom2.dot(n)
      denom += (dp2*dp2 / moi2)
    return if denom == 0 # coincident axes or weirdness
    
    J /= denom
    if !s1.isFixedLinear()
      s1.setVelocity(u1.add(n.x(J).div(m1)))
    if !s2.isFixedLinear()
      s2.setVelocity(u2.subtract(n.x(J).div(m2)))
    if !s1.isFixedAngular()
      s1.setAngularVelocity(om1 + J * dp1 / moi1)
    if !s2.isFixedAngular()
      s2.setAngularVelocity(om2 - j * dp2 / moi2)
  
    
    
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
  
  # determine if a point lies inside a circle
  # @param {Vector} pt point
  # @param {Circle} circle circle object
  pointInCircle = (pt, circle) ->
    dist = circle.pos.subtract(pt).mag()
    dist <= circle.radius
    
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
  {checkCollisions
  detectCollision
  circleWallCollision
  isImpendingCollision
  resolveCollision
  resolveCollisionFixed
  resolveInelasticCollisionFixed
  angularCollisionLineCircle
  angularCollisionLineCircle2
  angularCollisionLineStationaryLine
  angularCollisionLineLine
  pointInCircle
  pointInTriangle 
  pointInPolygon}
)()

# constants
collisions.NONE     = -1
collisions.EMBEDDED = -2

root = exports ? window
root.collisions = collisions