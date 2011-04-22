


module MUD
  class Place < MUD::Static
  
    # construct a new Place
    def initialize
      super
      @occupants = Array.new
      @desc = nil
	    @space = 0
	    @actionenter = ""
	    @actionleave = ""
	    @actionreply = ""
	    @attached_to = nil
    end
    
    # normal to_s method
    def to_s
	    arr = Array.new
	    arr.push(['empty'])
	    arr.push(['fixed'])
	    arr.push(['headline', @name])
	    arr.push(['leftnofill', @desc])
	    arr.push(['fixed'])
	    arr.push(['leftnofill', self.reply])
	    arr.push(['nofill', "Occupants"])
	    plarr = Array.new
	    @occupants.each do |p|
	      plarr.push 'nofill' if plarr.empty?
	      plarr.push p.name if p.status
		    if plarr.length == 5
		      arr.push plarr
		      plarr.clear
		    end
	    end
	    arr.push plarr if plarr.length > 1
	    arr.push(['fixed'])
	    return SUPPORT::Format::format(arr)
    end
	
	  # constructs enter string
	  # [param player:]		player that is entering
	  # [returns:]			  string
	  def enter (player)
	    return @actionenter.sub "%1", player.name
	  end
	
	  # constructs leave string
	  # [param player:]		player that is leaving
	  # [returns:]			  string
	  def leave (player)
	    return @actionleave.sub "%1", player.name
	  end
	
	  # constructs reply string
	  # [returns:]			  string
	  def reply
	    str = "#{@actionreply} ("
	    for i in 0...@occupants.length
	      str += "#{@occupants[i]}"
	      str += ", " if i < @occupants.length - 1
	    end
	    str += ")"
	    return @actionreply.sub "%1", "#{@occupants.length}/#{space}"
	  end
	
	  # lists the properties if this gridfield
	  # [returns:]			  array of information
	  def info
	    output = Array.new
	    output.push "id: #{self.id}"
	    output.push "name: #{self.name}"
	    output.push "desc: #{self.desc}"
	    output.push "space: #{self.space}"
	    output.push "action enter: #{self.actionenter}"
	    output.push "action leave: #{self.actionleave}"
	    output.push "action reply: #{self.actionreply}"
	    output.push "attached to: #{self.attached_to.id}"
	    return output
	  end
	
	  # add a new player to occupants
	  # [param player:]		player instance to add
	  # [returns:]			  boolean true if successful
	  def enqueue (player)
	    if @space > @occupants.length
	      @occupants.push player
		  return true
	    else
	      return false
	    end
	  end
	
	  # remove a new player from occupants
	  # [param player:]		player instance to remove
	  # [returns:]			  boolean true if successful
	  def dequeue (player)
	    if @occupants.include? player
	      @occupants.delete player
		    return true
	    else
	      return false
	    end
	  end
    
    attr_accessor :occupants, :desc, :space, :actionenter, :actionleave, :actionreply, :attached_to
  end
end
