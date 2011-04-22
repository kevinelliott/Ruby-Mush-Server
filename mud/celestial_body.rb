


module MUD
  class CelestialBody
    
    # [param n:]      name for the body
    # [param dd:]     direction the body moves around the gridcloud, either n, e, s, w
    # [param ct:]     how many days does the body take for a complete circle as number
    # [param vt:]     how long of a circle is the body visible in percent
    # [param bv:]     when will the body become visible in percent
    # [param sun:]    boolean true if body is a sun covering the gridcloud in light
    # [param pt:]     how long it takes for the body to move to the next phase (only non-suns)
    # [param p:]      array of the different phase-names (only non-suns)
    def initialize (n, dd, ct, vt, bv, sun, pt, p)
      @id = $WORLD.find_id
      $WORLD.register_object self
      @name = n
      @direction = dd
      @circle_time = ct
      @visible_time = (vt < 100) ? vt : 0
      @become_visible = (bv < 100) ? bv : 0
      @is_sun = sun
      @phases_time = pt
      @phases = p
    end
	
	# list the properties of this celestial body
	# [returns:]		array of information
	def info
		output = Array.new
		output.push "id: #{self.id}"
		output.push "name: #{self.name}"
		output.push "direction: #{self.direction}"
		output.push "circle time: #{self.circle_time}"
		output.push "visible time: #{self.visible_time}"
		output.push "become visible: #{self.become_visible}"
		output.push "is sun: #{self.is_sun}"
		output.push "phases time: #{self.phases_time}" if not self.is_sun
		output.push "phases: #{self.phases * ", "}" if not self.is_sun
		return output
	end
    
    attr_accessor :id, :name, :direction, :circle_time, :visible_time, :become_visible, :is_sun, :phases_time, :phases
  end
end
