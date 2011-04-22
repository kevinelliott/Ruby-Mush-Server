


module MUD
  class Doorkey < MUD::Static
  
    # construct a new Doorkey
    # [param f:]    field object, it is connected to
    # [param o:]    player id that owns the key
    def initialize (f, o)
      super()
      @field = f
      @ownerid = o
      @copies = Array.new
    end
    
    attr_accessor :field, :ownerid, :copies
  end
end
