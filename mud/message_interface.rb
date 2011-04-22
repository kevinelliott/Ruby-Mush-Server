

module MUD
  class MessageInterface
  
    # construct a new MessageInterface
    # init mapping from command to MessageProcessor method, mapping needs to be downcase
    def initialize
      @processor = MUD::MessageProcessor.new
      @special = {
        "special::delete"=>@processor.method(:special_delete),
      }
      @loggedoutcommands = {
        "register"=>@processor.method(:register),
        "login"=>@processor.method(:login),
        "logout"=>@processor.method(:logout),
      }
      @synonymecommands = {
        "\""=>@processor.method(:pose),
        "\'"=>@processor.method(:pose_say),
        "page"=>@processor.method(:whisper),
      }
      @loggedincommands = {
        "pose"=>@processor.method(:pose),
        "say"=>@processor.method(:pose_say),
        "whisper"=>@processor.method(:whisper),
        "\""=>@processor.method(:pose_say),
        "\'"=>@processor.method(:pose),
        "logout"=>@processor.method(:logout),
		    "look"=>@processor.method(:look),
		    "use"=>@processor.method(:use),
		    "leave"=>@processor.method(:leave),
		    "take"=>@processor.method(:take),
		    "drop"=>@processor.method(:drop),
		    "rent"=>@processor.method(:rent),
		    "abrogate"=>@processor.method(:abrogate),
		    "empower"=>@processor.method(:empower),
		    "deny"=>@processor.method(:deny),
		    "lock"=>@processor.method(:lock),
		    "unlock"=>@processor.method(:unlock),
		    "&"=>@processor.method(:and_cmd),
		    "+finger"=>@processor.method(:finger),
        "time"=>@processor.method(:time),
        "weather"=>@processor.method(:weather),
        "celestials"=>@processor.method(:celestials),
        "allcelestials"=>@processor.method(:allcelestials),
        "this"=>@processor.method(:this),
      }
      @buildercommands = {
        "@tspecs create"=>@processor.method(:tspecs_create),
        "@tspecs modify"=>@processor.method(:tspecs_modify),
        "@tspecs info"=>@processor.method(:tspecs_info),
        "@tspecs setdefault"=>@processor.method(:tspecs_setdefault),
        "@tspecs setboot"=>@processor.method(:tspecs_setboot),
        "@tspecs addcelestial"=>@processor.method(:tspecs_addcelestial),
        "@tspecs removecelestial"=>@processor.method(:tspecs_removecelestial),
        "@tspecs delete"=>@processor.method(:tspecs_delete),
        "@celestial create"=>@processor.method(:celestial_create),
		    "@celestial modify"=>@processor.method(:celestial_modify),
		    "@celestial info"=>@processor.method(:celestial_info),
        "@celestial delete"=>@processor.method(:celestial_delete),
        "@cloud create"=>@processor.method(:cloud_create),
	    	"@cloud info"=>@processor.method(:cloud_info),
        "@cloud tspecs"=>@processor.method(:cloud_tspecs),
        "@cloud weather"=>@processor.method(:cloud_weather),
        "@cloud delete"=>@processor.method(:cloud_delete),
        "@field create"=>@processor.method(:field_create),
		    "@field name"=>@processor.method(:field_name),
		    "@field rentable"=>@processor.method(:field_rentable),
		    "@field info"=>@processor.method(:field_info),
        "@field setcloud"=>@processor.method(:field_setcloud),
		    "@field sethome"=>@processor.method(:field_sethome),
		    "@field setregistration"=>@processor.method(:field_setregistration),
        "@field desc"=>@processor.method(:field_desc),
        "@field delete"=>@processor.method(:field_delete),
        "@connector create"=>@processor.method(:connector_create),
		    "@connector name"=>@processor.method(:connector_name),
		    "@connector info"=>@processor.method(:connector_info),
        "@connector twoway"=>@processor.method(:connector_twoway),
        "@connector lockable"=>@processor.method(:connector_lockable),
        "@connector source"=>@processor.method(:connector_source),
        "@connector target"=>@processor.method(:connector_target),
        "@connector delete"=>@processor.method(:connector_delete),
        "@weather create"=>@processor.method(:weather_create),
		    "@weather modify"=>@processor.method(:weather_modify),
		    "@weather info"=>@processor.method(:weather_info),
        "@weather delete"=>@processor.method(:weather_delete),
		    "@type"=>@processor.method(:type),
		    "@teleport"=>@processor.method(:teleport),
		    "@place create"=>@processor.method(:place_create),
		    "@place name"=>@processor.method(:place_name),
		    "@place info"=>@processor.method(:place_info),
		    "@place desc"=>@processor.method(:place_desc),
		    "@place space"=>@processor.method(:place_space),
		    "@place actionenter"=>@processor.method(:place_actionenter),
		    "@place actionleave"=>@processor.method(:place_actionleave),
		    "@place actionreply"=>@processor.method(:place_actionreply),
		    "@place attach"=>@processor.method(:place_attach),
		    "@place delete"=>@processor.method(:place_delete),
		    "@item create"=>@processor.method(:item_create),
		    "@item name"=>@processor.method(:item_name),
		    "@item info"=>@processor.method(:item_info),
		    "@item desc"=>@processor.method(:item_desc),
		    "@item actionuse"=>@processor.method(:item_actionuse),
		    "@item attach"=>@processor.method(:item_attach),
		    "@item delete"=>@processor.method(:item_delete),
      }
      @admincommands = {
        "$&"=>@processor.method(:all_and_cmd),
        "$player"=>@processor.method(:player_info),
        "$shutdown"=>@processor.method(:shutdown),
      }
    end
    
    # split and check incoming message for match on Processor map and pass it to the MessageProcessor method
    # [param addr:]     socket string representing the connection
    # [param msg:]      incoming message to be evaluated
    def incoming (addr, msg)
      cmd = nil
	    oldcmd = nil
      param = nil
	    oldparam = nil
      if msg =~ /^(\S+)$/
        cmd = $1
      elsif msg =~ /^(\S+)\s(.+)$/
        cmd = $1
        param = $2
		    oldcmd = cmd
		    oldparam = param
        if not self.match? cmd and $2 =~ /^(\S+)\s(.+)$/ and not cmd[0].chr == "&" and not cmd[1].chr == "&"
          cmd = cmd + " " + $1
          param = $2
	    	elsif self.match? cmd + " " + param and not cmd[0].chr == "&" and not cmd[1].chr == "&"
		      cmd = cmd + " " + param
		      param = nil
        end
      end
      # special commands first
      if cmd and self.is_special? cmd
        cmd = cmd.downcase
        @special[cmd].call addr, cmd, param
        return
      end
      if $WORLD.UPROC.is_logged_in? addr and cmd
        p = $WORLD.UPROC.player_object addr
        # regular logged in commands
        if self.loggedin_match? cmd
          cmd = cmd.downcase
          @loggedincommands[cmd].call addr, cmd, param
          return
        # attached commands for logged in
        elsif self.synonyme_match? cmd[0].chr
          param = cmd[1,cmd.size] + " " + param
          cmd = cmd[0].chr.downcase
          @synonymecommands[cmd].call addr, cmd, param
          return
        # movements through connector
        elsif $WORLD.UPROC.connector_available? addr, msg
          $WORLD.UPROC.move_player addr, msg
          return
        # builder commands for logged in
        elsif self.builder_match? cmd and p.role > 5
          @buildercommands[cmd].call addr, cmd, param
          return
        # admin commands for logged in
        elsif self.admin_match? cmd and p.role > 9
          @admincommands[cmd].call addr, cmd, param
          return
        # user-detail commands for logged in
        elsif cmd[0].chr == "$" and cmd[1].chr == "&" and p.role > 9
          @admincommands["$&"].call addr, cmd, param
          return
        # & commands for character customization
        elsif cmd[0].chr == "&"
          @loggedincommands["&"].call addr, cmd, param
          return
        end
      else
        # basic commands for not logged in
        if oldcmd and self.loggedout_match? oldcmd
          oldcmd = oldcmd.downcase
          @loggedoutcommands[oldcmd].call addr, oldcmd, oldparam
		    elsif cmd and self.loggedout_match? cmd
		      cmd = cmd.downcase
		      @loggedoutcommands[cmd].call addr, cmd, param
        end
      end
    end
    
    # does input match any map key?
    # [param cmd:]      input command
    # [returns:]        true if any match is found
    def match? (cmd)
      return (self.builder_match?(cmd) or self.loggedin_match?(cmd) or self.synonyme_match?(cmd) or self.admin_match?(cmd))
    end
    
    # does input match a logged out key?
    # [param cmd:]      input command
    # [returns:]        true if a match is found
    def loggedout_match? (cmd)
      return @loggedoutcommands.keys.include? cmd.downcase
    end
    
    # does input match a logged in key?
    # [param cmd:]      input command
    # [returns:]        true if a match is found
    def loggedin_match? (cmd)
      return @loggedincommands.keys.include? cmd.downcase
    end
    
    # does input match an synonyme key?
    # [param cmd:]      input command
    # [returns:]        true if a match is found
    def synonyme_match? (cmd)
      return @synonymecommands.keys.include? cmd.downcase
    end
    
    # does input match a builder key?
    # [param cmd:]      input command
    # [returns:]        true if a match is found
    def builder_match? (cmd)
      return @buildercommands.keys.include? cmd.downcase
    end
    
    # does input match an admin key?
    # [param cmd:]      input command
    # [returns:]        true if a match is found
    def admin_match? (cmd)
      return @admincommands.keys.include? cmd.downcase
    end
    
    # does input match a special key?
    # [param cmd:]      input command
    # [returns:]        true if a match is found
    def is_special? (msg)
      if msg =~ /^(\S+)($|\s.*$)/
        arr = @special.keys
        for i in 0...arr.length
          if $1.downcase == arr[i].downcase
            return true
          end
        end
      end
      return false
    end
  end
end
