


module MUD
  class Gridfield < MUD::Static
  
    # construct a new Gridfield
    def initialize
      super
      @connectors = Array.new
      @desc = ""
      @cloud = nil
	    @players = Array.new
	    @places = Array.new
	    @items = Array.new
	    @key = nil
	    @rentable = false
	    @locked = false
    end
    
    # normal to_s method
    def to_s
	    arr = Array.new
	    arr.push(['fixed'])
	    arr.push(['headline', @name])
	    arr.push(['leftnofill', @desc])
	    arr.push(['fixed'])
	    # list objects
	    arr.push(['headline', "Items"])
	    itarr = Array.new
	    @items.each do |i|
	      itarr.push 'nofill' if itarr.empty?
	      itarr.push "#{i.name}"
	      if itarr.length == 5
	        arr.push itarr
	        itarr.clear
	      end
	    end
	    arr.push itarr if itarr.length > 1
	    arr.push(['fixed'])
      # list places
	    arr.push(['headline', "Places"])
	    plarr = Array.new
	    @places.each do |p|
	      plarr.push 'nofill' if plarr.empty?
	      plarr.push "#{p.name} (#{p.occupants.length}/#{p.space})"
		    if plarr.length == 5
		      arr.push plarr
		      plarr.clear
		    end
	    end
	    arr.push plarr if plarr.length > 1
	    arr.push(['fixed'])
      # list players
	    arr.push(['headline', "Players"])
	    plarr = Array.new
	    @players.each do |p|
	      plarr.push 'nofill' if plarr.empty?
	      plarr.push p.name if p.status
		    if plarr.length == 5
		      arr.push plarr
		      plarr.clear
		    end
	    end
	    arr.push plarr if plarr.length > 1
	    arr.push(['fixed'])
      # list connectors
	    arr.push(['headline', "Connectors"])
	    @connectors.each do |c|
	      if c.way_exists? self
	        t = c.to_s(self)
	        if c.lockable and ($WORLD.object_map[c.grid1].locked or $WORLD.object_map[c.grid2].locked)
	          t += " (locked)"
	        elsif c.lockable and ($WORLD.object_map[c.grid1].key or $WORLD.object_map[c.grid2].key)
	          t += " (lockable)"
	        end
	        arr.push(['leftnofill', t])
	      end
	    end
	    arr.push(['fixed'])
      return SUPPORT::Format::format(arr)
    end
    
    # decide if a connector is valid by checking for name match and for a way from the gridfield through it
    # [returns:]      true if connector is valid
    def connector_valid? (name)
      found = false
      @connectors.each do |c|
        found = true if (c.way_exists? self and c.use_name(self).downcase == name.downcase)
      end
      return found
    end
    
    # find the destination field for valid name through a connector
    # [returns:]      destination field or nil
    def get_destination (name)
      @connectors.each do |c|
        return c.opposite(self) if (c.way_exists? self and c.use_name(self).downcase == name.downcase)
      end
      return nil
    end
	
	  # lists the properties of this gridfield
	  # [returns:]			array of information
	  def info
	    output = Array.new
	    output.push "id: #{self.id}"
	    output.push "name: #{self.name}"
	    output.push "desc: #{self.desc}"
	    output.push "rentable: #{self.rentable}"
	    output.push "rented: #{(self.key) ? self.key.ownerid.to_s + " (copies: " + (self.key.copies * ", ") + ")" : "nil"}"
	    output.push "locked: #{self.locked}"
	    output.push "cloud: #{(@cloud) ? @cloud.id : "nil"}"
	    output.push "connectors: "
	    for i in 0...@connectors.length
	      c = @connectors[i]
		    output[output.length - 1] += "#{c.id}"
		    output[output.length - 1] += ", " if i < @connectors.length - 1
	    end
	    output.push "places: "
	    for i in 0...@places.length
	      p = @places[i]
	      output[output.length - 1] += "#{p.id}"
	      output[output.length - 1] += ", " if i < @places.length - 1
	    end
	    output.push "items: "
	    for i in 0...@items.length
	      it = @items[i]
	      output[output.length - 1] += "#{it.id}"
	      output[output.length - 1] += ", " if i < @items.length - 1
	    end
	    return output
	  end
    
    attr_accessor :connectors, :cloud, :desc, :players, :places, :items, :key, :rentable, :locked
  end
end
