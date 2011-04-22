


module MUD
  class Connector < MUD::Static
  
    # construct a new Connector
    def initialize
      super
      @is_two_way = nil
      @grid1 = nil
      @grid2 = nil
      @name_opposite = nil
      @lockable = false
    end
    
    # find the opposite field to the specified field
    # [param field:]      specified field to find an opposite to
    # [returns:]          opposite field
    def opposite (field)
      return (field.id == @grid1) ? $WORLD.object_map[@grid2] : $WORLD.object_map[@grid1]
    end
    
    # find the name representation of the connector for the specified field
    # mainly used for listing all connectors on the field, allwing the player to travel
    # [param field:]      specified field for the name
    # [returns:]          name of the field
    def use_name (field)
      return (field.id == @grid1) ? @name : @name_opposite
    end
    
    # normal to_s method
    def to_s (field)
      m = "#{self.use_name field} (#{self.opposite(field).name})"
      return m
    end
    
    # is there a way off the specified field through the connector?
    # [param field:]      specified field to find a way off from
    # [returns:]          true if a way exists
    def way_exists? (field)
      return (not @is_two_way and not field.id == @grid1) ? false : true
    end
	
	  # lists the properties of this connector
	  # [returns:]			array of information
	  def info
	    output = Array.new
	    output.push "id: #{self.id}"
	    output.push "name: #{self.name}"
	    output.push "opposite name: #{self.name_opposite}"
	    output.push "is two-way: #{(@is_two_way) ? "yes" : "no"}"
	    output.push "grid1(source)-id: #{(@grid1) ? @grid1 : "nil"} grid2(target)-id: #{(@grid2) ? @grid2 : "nil"}"
	    return output
	  end
    
    attr_accessor :name_opposite, :grid1, :grid2, :is_two_way, :lockable
  end
end
