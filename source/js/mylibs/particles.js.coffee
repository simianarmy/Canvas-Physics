# General particle systems functions

#= require ./vec

particles = (->  
  # Calculates properties of a movable particle attached to a fixed 
  # point on by a undamped, uncoupled spring.
  # @param {Spring} spring the spring object
  # @param {Particle} p the particle object
  #   which must have a speed, direction, and mass
  # @param {Number} te total energy or null (it will be calculated)
  # @param {Number} ts time step
  # @param {Number} g gravity
  # @return {Object} name/result of calculations for:
  #   pos {Vector} new particle position
  #   speed {Number} new particle speed
  #   velocity {Vector} new particle velocity
  #   totalEnergy {Number} new total energy
  particleOnSpring = (spring, particle, te, ts, g) ->
    res = {}
    pspeed = particle.speed
    pmass = particle.mass
    v = spring.pnt1.subtract(spring.pnt2)
    d = v.mag()
    e = d - spring.length
    
    # calculate energy if necessary
    if te == null
      te = pmass * pspeed * pspeed / 2
      # elastic p.e.
      if (e > 0) || spring.isCompressive()
        epe = spring.elasticity * e * e / 2
        te += epe
      # grav. p.e.
      if g > 0
        gpe = pmass * g * spring.pnt2.e(2)
        te -= gpe
    
    # calculate force
    f = $V([0, pmass * g, 0])
    if (e > 0) || spring.isCompressive()
      if d > 0
        f.add v.x(spring.elasticity * e / d)
        
    # calculate new position
    a = f.divide(pmass)
    disp = particle.direction.x(pspeed * ts).add(a.x(ts * ts / 2))
    pos = spring.pnt2.add(disp)
    
    # calculate new elastic energy
    newd = pos.subtract(spring.pnt1).mag()
    newe = newd - spring.length
    if (newe > 0) || spring.isCompressive()
      epe = spring.elasticity * newe * newe / 2
    else
      epe = 0
    
    # calculate new kinetic energy and hence speed
    ke = te - epe + pmass * g * pos.e(2)
    if ke <= 0
      speed = 0
    else
      speed = Math.sqrt(2 * ke / pmass)
      velocity = disp.toUnitVector()
    
    {pos: pos
    speed: speed
    velocity: velocity
    totalEnergy: te}
    
  {particleOnSpring}
)()

root = exports ? window
root.particles = particles