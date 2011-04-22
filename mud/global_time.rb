


module MUD
  class GlobalTime
  
    # contruct a new global time
    def initialize
      @default_spec = nil
      @timespecs = Array.new
    end
    
    def register_tspec (tspec)
      @timespecs.push tspec
    end
    
    def unregister_tspec (tspec)
      @timespecs.delete tspec
    end
    
    def find_spec_id
      return (@timespecs.length > 0) ? @timespecs[@timespecs.length - 1].id.to_i + 1 : 1
    end
    
    def spec_exists? (tspec)
      return @timespecs.include? tspec
    end
    
    def spec_by_id (id)
      @timespecs.each do |t| return t if t.id.to_i == id.to_i end
      return nil
    end
    
    attr_accessor :default_spec, :timespecs
  end
end
