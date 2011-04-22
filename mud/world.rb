


module MUD
  class World
  
    # constructs the new world
    # [param controller:]       controller object running the main pipeline
    def initialize (controller)
      @controller = controller
      @globaltime = nil
      @MI = MUD::MessageInterface.new
      @UPROC = MUD::UserProcessor.new
      @gridclouds = Array.new
      @home_grid_field = nil
      @register_grid_field = nil
      @object_map = Hash.new # map any id to an object
      @empty_ids = Array.new
      @max_id = 1;
    end
    
    # register an object instance with the world, i.e. an id, that needs to be set BEFORE registering
    # [param obj:]      object instance to be registered
    def register_object (obj)
      if @object_map.has_key? obj.id
        obj.id = self.find_id
      end
      @object_map[obj.id] = obj
      if @max_id < obj.id
        @max_id = obj.id
      end
    end
    
    # unregister an object instance with the world
    # [param obj:]      object instance to be removed
    def unregister_object (obj)
      @object_map.delete obj.id if @object_map.has_key? obj.id
      @empty_ids.push obj.id if @max_id > obj.id
      @max_id = obj.id - 1 if @max_id <= obj.id
    end
    
    # register a cloud with the world
    def register_cloud (cloud)
      @gridclouds.push cloud
    end
    
    def unregister_cloud (cloud)
      @gridclouds.delete cloud
    end
    
    def cloud_by_id (id)
      @gridclouds.each do |c| return c if c.id == id end
      return nil
    end
    
    # fetch a new valid id from the pool
    # [returns:]        a valid id from the pool
    def find_id
      if @empty_ids.length > 0
        return @empty_ids.pop
      else
        return @max_id + 1
      end
    end
    
    # fetch a new valid cloud id by increasing last cloud id by one
    # [returns:]        a valid cloud id
    def find_cloud_id
      return (@gridclouds.length > 0) ? @gridclouds[@gridclouds.length-1].id + 1 : 1
    end
    
    # translates an abbreviation to the full name
    # [param abbr:]     abbreviation to be translated
    # [returns:]        full name or nil
    def World::full_name (abbr)
      name = case abbr
        when 'n' then 'north'
        when 'e' then 'east'
        when 'w' then 'west'
        when 's' then 'south'
        else nil
      end
      return name
    end
    
    # finds the opposite direction (takes abbreviations like n,s,e,w)
    # [param dir:]      abbreviated input direction
    # [returns:]        abbreviated opposite direction
    def World::opposite_direction (dir)
      opposite = case dir
        when 'n' then 's'
        when 's' then 'n'
        when 'e' then 'w'
        else 'e'
      end
      return opposite
    end
    
     attr_accessor :globaltime, :gridclouds, :object_map, :MI, :controller, :UPROC, :home_grid_field, :register_grid_field, :celestial_bodies
  end
end

