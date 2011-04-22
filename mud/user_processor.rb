

module MUD
  class UserProcessor
  
    # construct a new UserProcessor
    def initialize
      @map_addr_player = Hash.new
      @users = Array.new
    end
    
    # make the player leave all places
    # [param addr:]     socket string representing the connection
    def leave_places (addr)
      p = self.player_object addr
      field = $WORLD.object_map[p.parent]
      field.places.each do |place|
        if place.dequeue(p)
          field.players.each do |fp|
	          $WORLD.controller.create_message fp.status, place.leave(p) if fp.status
	        end
        end
      end
    end
    
    # player enters a field
    # [param addr:]     socket string representing the connection
    # [param field:]    destination field
    def enter_field (addr, field)
      p = self.player_object addr
      current = $WORLD.object_map[p.parent]
      return if not current
      field.players.each do |fp|
        str = "#{(fp.id == p.id) ? "You" : p.name} walk#{(fp.id == p.id) ? "" : "s"} in from #{current.name}."
        $WORLD.controller.create_message fp.status, str if fp.status
      end
    end
    
    # player leaves a field
    # [param addr:]     socket string representing the connection
    # [param field:]    destination field
    def leave_field (addr, field)
      p = self.player_object addr
      current = $WORLD.object_map[p.parent]
      return if not current
      current.players.each do |fp|
        str = "#{(fp.id == p.id) ? "You" : p.name} walk#{(fp.id == p.id) ? "" : "s"} out towards #{field.name}."
        $WORLD.controller.create_message fp.status, str if fp.status
      end
    end
    
    # prepare moving a player to a new field
    # [param addr:]     socket string representing the connection
    # [param name:]     name for the connector to the destination field
    def move_player (addr, name)
      p = self.player_object addr
      field = $WORLD.object_map[p.parent]
      destination = field.get_destination name
      connector = nil
      field.connectors.each do |c|
        connector = c if (c.grid1 == field.id and c.grid2 == destination.id) or (c.grid2 == field.id and c.grid1 == destination.id)
      end
      locked = true
      if connector and connector.lockable
        if not field.locked and not destination.locked
          locked = false
        elsif field.locked and (field.key.ownerid == p.id or field.key.copies.include?(p.id))
          locked = false
        elsif destination.locked and (destination.key.ownerid == p.id or destination.key.copies.include?(p.id))
          locked = false
        end
      else
        locked = false
      end
      if locked
        $WORLD.controller.create_message addr, "Connector to destination field is locked."
        return
      end
      self.leave_places addr
      self.leave_field addr, destination
      self.enter_field addr, destination
      self.relocate addr, destination if destination
    end
    
    # relocate the player to a new field
    # [param addr:]         socket string representing the connection
    # [param destination:]  destination field
    def relocate (addr, destination)
      p = self.player_object addr
	    $WORLD.object_map[p.parent].players.delete p if p.parent
      p.parent = destination.id
	    destination.players.push p
      $WORLD.controller.create_message addr, destination.to_s
    end
    
    # register a new player object to a player
    # [param addr:]     socket string representing the connection
    # [param param:]    string consisting of username and password ideally
    def register (addr, param)
      if param =~ /^(\S+)\s(\S+)$/
	      uname = $1
		    upass = $2
        exists = (self.player_by_login_name(uname) or self.player_by_name(uname) or uname.downcase.eql?("me"))
        if exists
          $WORLD.controller.create_message addr, "Name is already taken. Try another."
          return
		    elsif uname =~ /=|,/
		      $WORLD.controller.create_message addr, "Name cannot include = or ,."
          return
        end
        
        # create player object
        p = MUD::Player.new
        p.login_name = uname
        p.password = upass
        p.name = uname
        p.role = (@users.empty?) ? 10 : 0
		    p.status = addr
		    p.lastwhisper = nil
        @users.push p
        @map_addr_player[addr] = p
        $WORLD.controller.create_message addr, "Successfully registered and logged in. Welcome, #{p.name}"
        
        # position player on the grid
        if $WORLD.register_grid_field
          self.relocate addr, $WORLD.register_grid_field
        else
          $WORLD.controller.create_message addr, "There is no registration field defined yet. You are now in the void."
        end
      else
        $WORLD.controller.create_message addr, "Please provide a single-word username and a password for registration."
      end
    end
    
    # login a player into a player object
    # [param addr:]     socket string representing the connection
    # [param param:]    string consisting of username and password ideally
    def login (addr, param)
      if param =~ /^(\S+)\s(\S+)$/
        exists = nil
        @users.each do |u| exists = u if (u.login_name == $1 and u.password == $2) end
        if not exists
          $WORLD.controller.create_message addr, "Your login information was not correct."
          return
        end
        @map_addr_player[addr] = exists
        $WORLD.controller.create_message addr, "Successfully logged in. Welcome, #{exists.name}"
		    exists.status = addr
		    exists.lastwhisper = nil
        # position player on the grid
		    if exists.parent and $WORLD.object_map[exists.parent] and $WORLD.object_map[exists.parent].instance_of? MUD::Gridfield
		      self.relocate addr, $WORLD.object_map[exists.parent]
        elsif $WORLD.home_grid_field
          self.relocate addr, $WORLD.home_grid_field
        else
          $WORLD.controller.create_message addr, "There is no home field defined yet. You are now in the void."
        end
      else
        $WORLD.controller.create_message addr, "Please provide a username and a password for login."
      end
    end
    
    # logout a player, terminating the connection in the process; this works regardless of being logged in
    # [param addr:]       socket string representing the connection
    def logout (addr)
      # removing the object will be done by SPECIAL::DELETE call
      # close socket
      $WORLD.controller.create_message addr, "Closing connection..."
      $WORLD.controller.create_message addr, "SPECIAL::CLOSE_SOCKET"
      # set player status to nil
      p = self.player_object addr
      p.status = nil if p
    end
    
    # check if a socket connection is logged into a player object
    # [param addr:]       socket string representing the connection
    # [returns:]          true if socket connection is logged in
    def is_logged_in? (addr)
      return @map_addr_player.has_key? addr
    end
    
    # find the player object to a socket connection
    # [param addr:]       socket string representing the connection
    # [returns:]          player object or nil
    def player_object (addr)
      return @map_addr_player[addr]
    end
	
    # find player by name
    # [param name:]		playername
    # [returns:]			player instance or nil
    def player_by_name (name)
      @users.each {|p| return p if p.name.downcase == name.downcase}
      return nil
    end
    
    # find player by login_name
    # [param name:]		playerloginname
    # [returns:]			player instance or nil
    def player_by_login_name (name)
      @users.each {|p| return p if p.login_name.downcase == name.downcase}
      return nil
    end
    
    # remove a socket connection from the logged in list
    # [param addr:]       socket string representing the connection
    def remove_object (addr)
      @map_addr_player.delete addr
    end
    
    # check if a connector is available for a player and its corresponding player object location
    # [param addr:]       socket string representing the connection
    # [param name:]       string that is being matched to the connectors
    # [returns:]          true if a connector using name is available
    def connector_available? (addr, name)
      p = self.player_object addr
      return false if not p
      return false if not p.parent
      field = $WORLD.object_map[p.parent]
      return field.connector_valid? name
    end
    
    attr_reader :map_addr_player
  end
end
