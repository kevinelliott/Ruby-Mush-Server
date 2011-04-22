


module MUD
  class Item < MUD::Detachable
  
    # construct a new Item
    def initialize
      super
      @desc = nil
	    @actionuse = ""
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
	    return SUPPORT::Format::format(arr)
    end
	  
	  # constructs use string
	  # [param player:]		player that is using the item
	  # [returns:]			  string
	  def use (player)
	    return @actionuse.sub "%1", player.name
	  end
	
	  # lists the properties if this gridfield
	  # [returns:]			  array of information
	  def info
	    output = Array.new
	    output.push "id: #{self.id}"
	    output.push "name: #{self.name}"
	    output.push "desc: #{self.desc}"
	    output.push "action use: #{self.actionuse}"
	    output.push "attached to: #{self.attached_to.id}"
	    return output
	  end
    
    attr_accessor :desc, :actionuse, :attached_to
  end
end
