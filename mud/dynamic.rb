


module MUD
  class Dynamic < MUD::Object
    # pseudo abstract
    def initialize
      super
      @parent = nil
    end
  end
end
