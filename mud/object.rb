


module MUD
  class Object
  
    # construct a new Object
    def initialize
      @name = nil
      @id = $WORLD.find_id
      $WORLD.register_object self
    end
    
    # normal to_s method
    def to_s
      return @name
    end
    
    attr_accessor :name, :id
  end
end
