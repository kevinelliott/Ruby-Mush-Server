

module MUD
  
  # class MessageProcessor consists of classes that represent the input of the User, mapping them onto local methods
  class MessageProcessor
    def initialize
      
    end
    def pose (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
	    return if not p.parent
	    field = $WORLD.object_map[p.parent]
	    field.players.each do |fp|
	      $WORLD.controller.create_message fp.status, "#{p.name} #{param}" if fp.status and not fp.id == p.id
	    end
    end
    def pose_say (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
	    return if not p.parent
	    field = $WORLD.object_map[p.parent]
	    field.players.each do |fp|
	      $WORLD.controller.create_message fp.status, "#{p.name} says: \"#{param}\"" if fp.status and not fp.id == p.id
	    end
    end
    def whisper (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
      if param =~ /[^\%]=/ and param =~ /^([^=]+)=(.+)$/
	      w = nil
	      if p.lastwhisper and p.lastwhisper.name == $1
		      w = p.lastwhisper
		    else
		      w = $WORLD.UPROC.player_by_name $1
		    end
		    if w
		      if w.status
		        p.lastwhisper = w
		        $WORLD.controller.create_message w.status, "From afar, #{p.name} #{$2}"
		      else
		        $WORLD.controller.create_message addr, "User #{$1} is not logged in."
		      end
		    else
		      $WORLD.controller.create_message addr, "User #{$1} was not found."
		    end
      elsif p.lastwhisper and p.lastwhisper.status
        $WORLD.controller.create_message p.lastwhisper.status, "From afar, #{p.name} #{param}"
	    end
    end
    def special_delete (addr, cmd, param)
	    if $WORLD.UPROC.is_logged_in? addr
	      p = $WORLD.UPROC.player_object addr
		    p.status = nil
		    $WORLD.UPROC.remove_object addr
	    end
    end
    def register (addr, cmd, param)
      $WORLD.UPROC.register addr, param
    end
    def login (addr, cmd, param)
      $WORLD.UPROC.login addr, param
    end
    def logout (addr, cmd, param)
      $WORLD.UPROC.logout addr
    end
	  def look (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    return if not p.parent
	    field = $WORLD.object_map[p.parent]
	    
	    # if param is not found
	    if not param
	      field = $WORLD.object_map[p.parent]
	      $WORLD.controller.create_message addr, field.to_s
	      return
	    end
	    
	    # param exists somewhere, as player, place or object
	    if param.downcase.eql?("me")
	      param = p.name
	    end
	    found = nil
	    field.players.each do |pl|
	      found = pl if pl.name.downcase == param.downcase
	    end
	    if found
	      $WORLD.controller.create_message addr, found.to_desc
	      return
	    end
	    field.items.each do |i|
	      found = i if i.name.downcase == param.downcase
	    end
	    if found
	      $WORLD.controller.create_message addr, found.to_s
	      return
	    end
	    field.places.each do |pl|
	      found = pl if pl.name.downcase == param.downcase
	    end
	    if found
	      $WORLD.controller.create_message addr, found.to_s
	      return
	    end
	    p.items.each do |i|
	      found = i if i.name.downcase == param.downcase
	    end
	    if found
	      $WORLD.controller.create_message addr, found.to_s
	      return
	    end
	    $WORLD.controller.create_message addr, "Nothing found."
	  end
	  def use (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    # use a place
	    found = nil
	    field.places.each do |place|
	      found = place if place.name.downcase == param.downcase
	    end
	    if found
	      $WORLD.UPROC.leave_places addr
	      if found.enqueue(p)
	        field.players.each do |fp|
	          $WORLD.controller.create_message fp.status, found.enter(p) if fp.status
	        end
	      else
  	      $WORLD.controller.create_message addr, found.reply
	      end
	      return
	    end
	    # use an object/item
	    found = nil
	    p.items.each do |item|
	      found = item if item.name.downcase == param.downcase
	    end
	    field.items.each do |item|
	      found = item if item.name.downcase == param.downcase
	    end
	    if found
	      field.players.each do |fp|
	        $WORLD.controller.create_message fp.status, found.use(p) if fp.status
	      end
	      return
	    end
	  end
	  def leave (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    # leave a place
	    $WORLD.UPROC.leave_places addr
	  end
	  def take (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    found = nil
	    field.items.each do |item|
	      found = item if item.name.downcase == param.downcase
	    end
	    if found
	      field.items.delete found
        found.attached_to = p
        p.items.push found
	      field.players.each do |fp|
	        $WORLD.controller.create_message fp.status, "#{p.name} picks up #{found.name}." if fp.status
	      end
	    end
	  end
	  def drop (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    found = nil
	    p.items.each do |item|
	      found = item if item.name.downcase == param.downcase
	    end
	    if found
	      p.items.delete found
        found.attached_to = field
        field.items.push found
	      field.players.each do |fp|
	        $WORLD.controller.create_message fp.status, "#{p.name} drops #{found.name}." if fp.status
	      end
	    end
	  end
	  def rent (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    rented = nil
      if param =~ /^(\d+)$/
        if f = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
          if f.rentable and not f.key
            rented = f
          elsif f.rentable
            $WORLD.controller.create_message addr, "Room has been rented out already."
          end
        end
      elsif param =~ /^here$/ and field.rentable and not field.key
        rented = field
      elsif param =~ /^here$/ and field.rentable
        $WORLD.controller.create_message addr, "Room has been rented out already."
      end
      if rented
        rented.key = MUD::Doorkey.new rented, p.id
        p.keys.push rented.key
        $WORLD.controller.create_message addr, "Room \"#{rented.name}\" rented. Id: #{rented.id}."
      end
    end
    def abrogate (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    rented = nil
      if param =~ /^(\d+)$/
        if f = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
          if f.key and f.key.ownerid == p.id
            rented = f
          end
        end
      elsif param =~ /^here$/ and field.key and field.key.ownerid == p.id
        rented = field
      end
      if rented
        rented.key.copies.each do |k|
          pobj = $WORLD.object_map[k]
          pobj.keycopies.delete rented.key
        end
        p.keys.delete rented.key
        $WORLD.unregister_object rented.key
        rented.key = nil
        rented.locked = false
        $WORLD.controller.create_message addr, "Room \"#{rented.name}\" abrogated. Id: #{rented.id}."
      end
    end
		def empower (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    rented = nil
	    emp = nil
      if param =~ /^(\d+)\s(.+)$/
        if f = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of?(MUD::Gridfield) and emp = $WORLD.UPROC.player_by_name($2)
          if f.key and f.key.ownerid == p.id
            rented = f
          end
        end
      elsif param =~ /^(here)\s(.+)$/ and field.key and field.key.ownerid == p.id
        rented = field if emp = $WORLD.UPROC.player_by_name($2)
      end
      if rented and emp
        emp.keycopies.push rented.key
        rented.key.copies.push emp.id
        $WORLD.controller.create_message addr, "Room \"#{rented.name}\" key copied to: #{emp.name}."
      end
    end
    def deny (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    rented = nil
	    emp = nil
      if param =~ /^(\d+)\s(.+)$/
        if f = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of?(MUD::Gridfield) and emp = $WORLD.UPROC.player_by_name($2)
          if f.key and f.key.ownerid == p.id
            rented = f
          end
        end
      elsif param =~ /^here\s(.+)$/ and field.key and field.key.ownerid == p.id
        rented = field if emp = $WORLD.UPROC.player_by_name($2)
      end
      if rented and emp and emp.keycopies.include?(rented.key)
        emp.keycopies.delete rented.key
        rented.key.copies.delete emp.id
        $WORLD.controller.create_message addr, "Room \"#{rented.name}\" key denied for: #{emp.name}."
      end
    end
    def lock (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    rented = nil
      if field.key and (field.key.ownerid == p.id or field.key.copies.include?(p.id))
        rented = field
      end
      if rented and not rented.locked
        rented.locked = true
        $WORLD.controller.create_message addr, "Room \"#{rented.name}\" has been locked."
      end
    end
    def unlock (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    field = $WORLD.object_map[p.parent]
	    rented = nil
      if field.key and (field.key.ownerid == p.id or field.key.copies.include?(p.id))
        rented = field
      end
      if rented and rented.locked
        rented.locked = false
        $WORLD.controller.create_message addr, "Room \"#{rented.name}\" has been unlocked."
      end
    end
    def and_cmd (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
      fnc = cmd[1,cmd.length-1]
      data = (param) ? param : ""
      if cmd =~ /^&(\S+)\s(\S+)$/
        fnc = $1
        data = $2 + " " + data
      end
      data = data.strip
      set = false
      if fnc == "name" and (not $WORLD.UPROC.player_by_name(data) or $WORLD.UPROC.player_by_name(data).id == p.id) and (not $WORLD.UPROC.player_by_login_name(data) or $WORLD.UPROC.player_by_login_name(data).id == p.id) and not data =~ /=|,/ and not data.downcase.eql?("me") and data.length > 0
        p.name = data
        set = true
      elsif fnc == "name"
        $WORLD.controller.create_message addr, "One of these errors occured: Name already taken; Name includes = or ,; Name has 0 characters"
        return
      end
      if fnc == "password" and not data =~ /\s/
        p.password = data
        set = true
      elsif fnc == "password"
        $WORLD.controller.create_message addr, "The following error occured: Password cannot include spaces."
        return
      end
      if fnc == "desc"
        p.desc = data
        set = true
      end
      if not set
        p.attrib[fnc] = data if data.length > 0
        p.attrib.delete fnc if data.length == 0
        set = true
      end
      $WORLD.controller.create_message addr, "Attribute \"#{fnc}\" set." if set
    end
    def all_and_cmd (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
      fnc = cmd[2,cmd.length-1]
      target = false
      data = (param) ? param : ""
      if cmd =~ /^@&(\S+)\s(\S+)$/
        fnc = $1
        data = $2 + " " + data
      end
      if data =~ /^([^=]+)=(.+)$/
        target = $1
        data = $2
      end
      puts fnc
      puts target
      puts data
      return if not target
      data = data.strip
      set = false
      t = $WORLD.UPROC.player_by_name(target)
      if not t
        $WORLD.controller.create_message addr, "The following error occured: Target playername not found."
        return
      end
      if fnc == "name" and (not $WORLD.UPROC.player_by_name(data) or $WORLD.UPROC.player_by_name(data).id == p.id) and (not $WORLD.UPROC.player_by_login_name(data) or $WORLD.UPROC.player_by_login_name(data).id == p.id) and not data =~ /=|,/ and not data.downcase.eql?("me") and data.length > 0
        t.name = data
        set = true
      elsif fnc == "name"
        $WORLD.controller.create_message addr, "One of these errors occured: Name already taken; Name includes = or ,; Name has 0 characters;"
        return
      end
      if fnc == "password" and not data =~ /\s/ 
        t.password = data
        set = true
      elsif fnc == "password"
        $WORLD.controller.create_message addr, "The following error occured: Password cannot include spaces."
        return
      end
      if fnc == "role" and data =~ /\d/ and data.to_i >= 0 and data.to_i <= 10
        t.role = data.to_i
        set = true
      elsif fnc == "role"
        $WORLD.controller.create_message addr, "The following error occured: Role is no round number between 0 and 10."
        return
      end
      if fnc == "desc"
        t.desc = data
        set = true
      end
      if not set
        t.attrib[fnc] = data if data.length > 0
        t.attrib.delete fnc if data.length == 0
        set = true
      end
      $WORLD.controller.create_message addr, "Attribute \"#{fnc}\" for \"#{t.name}\" set." if set
    end
    def finger (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
      if param.downcase.eql?("me")
        param = p.name
      end
      if u = $WORLD.UPROC.player_by_name(param)
        $WORLD.controller.create_message addr, u.to_s
      end
    end
    def time (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
      field = (p.parent) ? p.parent : nil
      field = $WORLD.object_map[field] if field
      cloud = field.cloud if field
      t = cloud.get_tspecs.compute_time if cloud and cloud.get_tspecs
      $WORLD.controller.create_message addr, t*"%n" if field and cloud and t
    end
    def weather (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
      field = (p.parent) ? p.parent : nil
      field = $WORLD.object_map[field] if field
      cloud = field.cloud if field
      weather = cloud.weather.to_s if cloud and cloud.weather
      $WORLD.controller.create_message addr, weather*"%n" if field and cloud and weather
    end
    def celestials (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
      field = (p.parent) ? p.parent : nil
      field = $WORLD.object_map[field] if field
      cloud = field.cloud if field
      t = cloud.get_tspecs.compute_celestial_bodies if cloud and cloud.get_tspecs
      $WORLD.controller.create_message addr, t*"%n" if field and cloud and t
    end
    def allcelestials (addr, cmd, param)
      p = $WORLD.UPROC.player_object addr
      field = (p.parent) ? p.parent : nil
      field = $WORLD.object_map[field] if field
      cloud = field.cloud if field
      t = cloud.get_tspecs.list_celestial_bodies if cloud and cloud.get_tspecs
      $WORLD.controller.create_message addr, t*"%n" if field and cloud and t
    end
    def this (addr, cmd, param)
	    p = $WORLD.UPROC.player_object addr
	    return if not p.parent
	    field = $WORLD.object_map[p.parent]
	    $WORLD.controller.create_message addr, "Current Gridfield-Id: #{field.id}."
	  end
    def tspecs_create (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)\s(\d+)\s(.*)\s(\d+)$/
        s = MUD::TimeSpecifics.new $1.to_i, $2.to_i, $3.to_i, $4.split(","), $5.to_i
        $WORLD.controller.create_message addr, "TimeSpec created. Id: #{s.id}."
      end
    end
    def tspecs_modify (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)\s(\d+)\s(\d+)\s(.*)\s(\d+)$/
        if spec = $WORLD.globaltime.spec_by_id($1)
          spec.year_len = $2.to_i
          spec.month_len = $3.to_i
          spec.day_len = $4.to_i
          spec.seasons = $5.split(",")
          spec.baseyear = $6.to_i
          $WORLD.controller.create_message addr, "TimeSpec-Id: #{$1} has been modified."
        end
      end
    end
    def tspecs_info (addr, cmd, param)
      if param =~ /^(\d+)$/
        if spec = $WORLD.globaltime.spec_by_id($1)
          $WORLD.controller.create_message addr, "TimeSpec-Id: #{$1} has the following properties:%n#{spec.info * "%n"}"
        end
      end
    end
    def tspecs_setdefault (addr, cmd, param)
      if param =~ /^(\d+)$/
        if spec = $WORLD.globaltime.spec_by_id($1)
          $WORLD.globaltime.default_spec = spec
          $WORLD.controller.create_message addr, "TimeSpec-Id: #{$1} has been flagged as default."
        end
      end
    end
    def tspecs_setboot (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)\s(\d+)\s(\d+)$/
        if spec = $WORLD.globaltime.spec_by_id($1)
          puts "\nSpec ID: #{spec.id}"
          puts spec.compute_time * "\n"
          begin
            spec.firstboot = Time.utc $4.to_i, $3.to_i, $2.to_i
            puts spec.compute_time * "\n"
            $WORLD.controller.create_message addr, "TimeSpec-Id: #{$1} boots on #{spec.firstboot.to_s}."
          rescue ArgumentError
            $WORLD.controller.create_message addr, "Error: Time format should be %day %month %year."
          end
        end
      end
    end
    def tspecs_addcelestial (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)$/
        if spec = $WORLD.globaltime.spec_by_id($1) and body = $WORLD.object_map[$2.to_i] and $WORLD.object_map[$2.to_i].instance_of? MUD::CelestialBody
          spec.register_celestial body
          $WORLD.controller.create_message addr, "TimeSpec-Id: #{$1} has registered a celestial body with the Id: #{$2}."
        end
      end
    end
    def tspecs_removecelestial (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)$/
        if spec = $WORLD.globaltime.spec_by_id($1) and body = $WORLD.object_map[$2.to_i] and $WORLD.object_map[$2.to_i].instance_of? MUD::CelestialBody
          spec.unregister_celestial body
          $WORLD.controller.create_message addr, "TimeSpec-Id: #{$1} has unregistered a celestial body with the Id: #{$2}."
        end
      end
    end
    def tspecs_delete (addr, cmd, param)
	    if param =~ /^(\d+)$/
        if spec = $WORLD.globaltime.spec_by_id($1)
          $WORLD.globaltime.unregister_tspec spec
          $WORLD.globaltime.default_spec = nil if $WORLD.globaltime.default_spec.id == spec.id
          for i in 0...$WORLD.gridclouds.length
            cloud = $WORLD.gridclouds[i]
            cloud.tspecs = nil if cloud.tspecs == spec.id
          end
          $WORLD.controller.create_message addr, "TimeSpec-Id: #{$1} deleted. Possible defaults and references have been removed."
        end
    	end
    end
    def celestial_create (addr, cmd, param)
      if param =~ /^(\S+)\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\d)\s(\d+)\s(.*)$/
        if (['w','e','n','s'].include? $2.downcase) and ($6 == "0")
          b = MUD::CelestialBody.new $1, $2, $3.to_i, $4.to_i, $5.to_i, ($6 == "1") ? true : false, $7.to_i, $8.split(",")
          $WORLD.controller.create_message addr, "Celestial Body created. Id: #{b.id}."
        end
      elsif param =~ /^(\S+)\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\d)$/
        if (['w','e','n','s'].include? $2.downcase) and ($6 == "1")
          b = MUD::CelestialBody.new $1, $2, $3.to_i, $4.to_i, $5.to_i, ($6 == "1") ? true : false, nil, nil
          $WORLD.controller.create_message addr, "Celestial Body created. Id: #{b.id}."
        end
      end
    end
	  def celestial_modify (addr, cmd, param)
	    cel = id = name = dir = ct = vt = bv = sun = pt = p = nil
	    if param =~ /^(\d+)\s(\S+)\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\d)\s(\d+)\s(.*)$/
        if (['w','e','n','s'].include? $3.downcase) and ($7 == "0")
		      id = $1.to_i
		      name = $2
		      dir = $3
		      ct = $4.to_i
		      vt = $5.to_i
		      bv = $6.to_i
		      sun = ($7 == "1") ? true : false
		      pt = $8.to_i
		      p = $9.split ","
        end
      elsif param =~ /^(\d+)\s(\S+)\s(\S+)\s(\d+)\s(\d+)\s(\d+)\s(\d)$/
        if (['w','e','n','s'].include? $3.downcase) and ($7 == "1")
		      id = $1.to_i
		      name = $2
		      dir = $3
		      ct = $4.to_i
		      vt = $5.to_i
		      bv = $6.to_i
		      sun = ($7 == "1") ? true : false
        end
      end
	    cel = $WORLD.object_map[id] if id
	    return if not cel or not cel.instance_of? MUD::CelestialBody
	    cel.name = name if name
	    cel.direction = dir if dir
	    cel.circle_time = ct if ct
	    cel.visible_time = vt if vt
	    cel.become_visible = bv if bv
	    cel.is_sun = sun if not sun.instance_of? NilClass
	    cel.phases_time = pt if pt and not sun
	    cel.phases = p if p and not sun
	    $WORLD.controller.create_message addr, "Celestial Body modified. Id: #{cel.id}."
	  end
	  def celestial_info (addr, cmd, param)
	    if param =~ /^(\d+)$/
		    if body = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::CelestialBody
		      $WORLD.controller.create_message addr, "Celestial Body-Id: #{body.id} has the following properties:%n#{body.info * "%n"}"
		    end
	    end
	  end
    def celestial_delete (addr, cmd, param)
      if param =~ /^(\d+)$/
        if body = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::CelestialBody
          $WORLD.unregister_object body
          for i in 0...$WORLD.globaltime.timespecs.length
            spec = $WORLD.globaltime.timespecs[i]
            spec.unregister_celestial body.id
          end
          $WORLD.controller.create_message addr, "Celestial Body deleted. Id: #{body.id}."
        end
      end
    end
    def cloud_create (addr, cmd, param)
      cloud = MUD::GridCloud.new
	    $WORLD.controller.create_message addr, "GridCloud created. Id: #{cloud.id}."
    end
	  def cloud_info (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if cloud = $WORLD.cloud_by_id($1.to_i)
		      $WORLD.controller.create_message addr, "GridCloud-Id: #{cloud.id} has the following properties:%n#{cloud.info * "%n"}"
		    end
	    end
    end
    def cloud_tspecs (addr, cmd, param)
	    if param =~ /^(\d+)\s(\d+)$/
	      if spec = $WORLD.globaltime.spec_by_id($2.to_i) and cloud = $WORLD.cloud_by_id($1.to_i)
		      cloud.tspecs = spec
		      $WORLD.controller.create_message addr, "GridCloud-Id: #{cloud.id} assigned Timespec-Id: #{spec.id}"
		    end
      elsif param =~ /^(\d+)$/
	      if cloud = $WORLD.cloud_by_id($1.to_i)
		      cloud.tspecs = nil
		      $WORLD.controller.create_message addr, "GridCloud-Id: #{cloud.id} assigned Timespec-Id: nil"
		    end
	    end
    end
    def cloud_weather (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)$/
	      if cloud = $WORLD.cloud_by_id($1.to_i) and weather = $WORLD.object_map[$2.to_i] and $WORLD.object_map[$2.to_i].instance_of? MUD::Weather
		      cloud.weather = weather
		      $WORLD.controller.create_message addr, "GridCloud-Id: #{cloud.id} assigned Weather-Id: #{weather.id}"
		    end
      elsif param =~ /^(\d+)$/
	      if cloud = $WORLD.cloud_by_id($1.to_i)
		      cloud.weather = nil
		      $WORLD.controller.create_message addr, "GridCloud-Id: #{cloud.id} assigned Weather-Id: nil"
		    end
	    end
    end
    def cloud_delete (addr, cmd, param)
      if param =~ /^(\d+)$/
	      if cloud = $WORLD.cloud_by_id($1.to_i)
		      $WORLD.unregister_cloud cloud
		      str = cloud.gridfields * ", "
		      for i in 0...cloud.gridfields.length
		        f = $WORLD.object_map[cloud.gridfields[i]]
			      f.cloud = nil if f.instance_of? MUD::Gridfield
		      end
		      $WORLD.controller.create_message addr, "GridCloud-Id: #{cloud.id} removed. Gridfields: #{str} are now cloudless."
		    end
	    end
    end
    def field_create (addr, cmd, param)
      field = MUD::Gridfield.new
	    $WORLD.controller.create_message addr, "Gridfield created. Id: #{field.id}."
    end
	  def field_name (addr, cmd, param)
      if param =~ /^(\d+)\s(.+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      field.name = $2
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} name set: #{field.name}"
		    end
	    end
    end
    def field_rentable (addr, cmd, param)
      if param =~ /^(\d+)\s(\d)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      field.rentable = true if $2 == "1"
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} rentable set: #{field.rentable}"
		    end
	    end
    end
	  def field_info (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} has the following properties:%n#{field.info * "%n"}"
		    end
	    end
	  end
    def field_setcloud (addr, cmd, param)
	    if param =~ /^(\d+)\s(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield and cloud = $WORLD.cloud_by_id($2.to_i)
		      field.cloud.unregister_field field if field.cloud
		      field.cloud = cloud
		      cloud.register_field field
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} assigned GridCloud-Id: #{cloud.id}"
		    end
      elsif param =~ /^(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      field.cloud.unregister_field field if field.cloud
		      field.cloud = nil
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} assigned GridCloud-Id: nil"
		    end
	    end
    end
	  def field_sethome (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield and cloud = $WORLD.cloud_by_id($2.to_i)
		      $WORLD.home_grid_field = field
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} has been made home."
		    end
      elsif param =~ /^nil$/
	      $WORLD.home_grid_field = nil
		    $WORLD.controller.create_message addr, "Home has been set to: nil"
	    end
    end
	  def field_setregistration (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield and cloud = $WORLD.cloud_by_id($2.to_i)
		      $WORLD.register_grid_field = field
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} has been made registration default."
		    end
      elsif param =~ /^nil$/
	      $WORLD.register_grid_field = nil
		    $WORLD.controller.create_message addr, "Registration default has been set to: nil"
	    end
    end
    def field_desc (addr, cmd, param)
      if param =~ /^(\d+)\s(.+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      field.desc = $2
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} description set: #{field.desc}"
		    end
	    elsif param =~ /^(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      field.desc = nil
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} description set: nil"
		    end
	    end
    end
    def field_delete (addr, cmd, param)
      if param =~ /^(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      field.cloud.unregister_field field if field.cloud
		      field.connectors.each do |c|
		        c.grid1 = nil if c.grid1 == field.id
			      c.grid2 = nil if c.grid2 == field.id
			      $WORLD.object_map[c.grid1].connectors.delete c
			      $WORLD.object_map[c.grid2].connectors.delete c
			      $WORLD.unregister_object c
		      end
		      field.places.each do |p|
		        $WORLD.unregister_object p
		      end
		      field.places.clear
		      $WORLD.unregister_object field
		      $WORLD.controller.create_message addr, "Gridfield-Id: #{field.id} removed. All Connectors and Places were deleted."
		    end
	    end
    end
    def connector_create (addr, cmd, param)
      c = MUD::Connector.new
	    $WORLD.controller.create_message addr, "Connector created. Id: #{c.id}."
    end
	  def connector_name (addr, cmd, param)
      if param =~ /^(\d+)\s([^,]+)($|,\s?(.+)$)/
        if c = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Connector
		      c.name = $2
		      c.name_opposite = ($4) ? $4 : nil
		      $WORLD.controller.create_message addr, "Connector-Id: #{c.id} name set: #{c.name} and opposite name: #{(c.name_opposite) ? c.name_opposite : "not set"}"
		    end
	    end
    end
	  def connector_info (addr, cmd, param)
      if param =~ /^(\d+)$/
	      if c = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Connector
		      $WORLD.controller.create_message addr, "Connector-Id: #{c.id} has the following properties:%n#{c.info * "%n"}"
		    end
	    end
    end
    def connector_twoway (addr, cmd, param)
      if param =~ /^(\d+)\s(\d)$/
	      if c = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Connector
		      c.is_two_way = ($2 == "1") ? true : false
		      $WORLD.controller.create_message addr, "Connector-Id: #{c.id} is two-way: #{c.is_two_way}"
		    end
	    end
    end
    def connector_lockable (addr, cmd, param)
      if param =~ /^(\d+)\s(\d)$/
	      if c = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Connector
		      c.lockable = ($2 == "1") ? true : false
		      $WORLD.controller.create_message addr, "Connector-Id: #{c.id} is lockable: #{c.is_two_way}"
		    end
	    end
    end
    def connector_source (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)$/
	      if c = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Connector and field = $WORLD.object_map[$2.to_i] and $WORLD.object_map[$2.to_i].instance_of? MUD::Gridfield
		      c.grid1 = field.id
		      field.connectors.push c
		      $WORLD.controller.create_message addr, "Connector-Id: #{c.id} grid1 (source) set: #{c.grid1}"
		    end
	    end
    end
    def connector_target (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)$/
	      if c = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Connector and field = $WORLD.object_map[$2.to_i] and $WORLD.object_map[$2.to_i].instance_of? MUD::Gridfield
		      c.grid2 = field.id
		      field.connectors.push c
		      $WORLD.controller.create_message addr, "Connector-Id: #{c.id} grid2 (target) set: #{c.grid2}"
		    end
	    end
    end
    def connector_delete (addr, cmd, param)
      if param =~ /^(\d+)$/
	      if c = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Connector
		      $WORLD.object_map[c.grid1].connectors.delete c if c.grid1
		      $WORLD.object_map[c.grid2].connectors.delete c if c.grid2
		      $WORLD.unregister_object c
		      $WORLD.controller.create_message addr, "Connector-Id: #{c.id} removed."
		    end
	    end
    end
    def weather_create (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)\s(\d+)$/
	      w = MUD::Weather.new $1.to_i, $2.to_i, $3.to_i
		    $WORLD.controller.create_message addr, "Weather created. Id: #{w.id}."
	    end
    end
	  def weather_modify (addr, cmd, param)
      if param =~ /^(\d+)\s(\d+)\s(\d+)\s(\d+)$/
        if w = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Weather
	        w.humidity = $2.to_i
	        w.temperature = $3.to_i
	        w.wind_level = $4.to_i
	        $WORLD.controller.create_message addr, "Weather-Id: #{w.id} has been modified."
	      end
	    end
    end
	  def weather_info (addr, cmd, param)
      if param =~ /^(\d+)$/
	      if w = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Weather
		      $WORLD.controller.create_message addr, "Weather-Id: #{w.id} has the following properties:%n#{w.info * "%n"}"
		    end
	    end
    end
    def weather_delete (addr, cmd, param)
      if param =~ /^(\d+)$/
	      if w = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Weather
		      $WORLD.unregister_object w
		      $WORLD.gridclouds.each do |c|
		        c.weather = nil if c.weather and c.weather.id == w.id
		      end
		      $WORLD.controller.create_message addr, "Weather-Id: #{w.id} removed."
		    end
	    end
    end
	  def teleport (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if field = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Gridfield
		      $WORLD.UPROC.relocate addr, field
		    end
	    end
	  end
	  def type (addr, cmd, param)
	    if param =~ /^(\d+)$/
        $WORLD.controller.create_message addr, "Id: #{$1.to_i} is of the type #{$WORLD.object_map[$1.to_i].class}."
	    end
	  end
	  def place_create (addr, cmd, param)
	    p = MUD::Place.new
	    $WORLD.controller.create_message addr, "Place created. Id: #{p.id}."
	  end
	  def place_name (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        p.name = $2
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} name set: #{p.name}."
	      end
	    end
	  end
	  def place_info (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} has the following properties:%n#{p.info * "%n"}."
	      end
	    end
	  end
	  def place_desc (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        p.desc = $2
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} desc set: #{p.desc}."
	      end
	    end
	  end
	  def place_space (addr, cmd, param)
	    if param =~ /^(\d+)\s(\d+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        p.space = $2.to_i
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} space set: #{p.space}."
	      end
	    end
	  end
	  def place_actionenter (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        p.actionenter = $2
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} action-enter set: #{p.actionenter}."
	      end
	    end
	  end
	  def place_actionleave (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        p.actionleave = $2
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} action-leave set: #{p.actionleave}."
	      end
	    end
	  end
	  def place_actionreply (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        p.actionreply = $2
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} action-reply set: #{p.actionreply}."
	      end
	    end
	  end
	  def place_attach (addr, cmd, param)
	    if param =~ /^(\d+)\s(\d+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place and field = $WORLD.object_map[$2.to_i] and $WORLD.object_map[$2.to_i].instance_of? MUD::Gridfield
	        p.attached_to.places.delete p if p.attached_to
	        p.attached_to = field
	        field.places.push p
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} attachment set to Gridfield-Id: #{field.id}."
	      end
	    end
	  end
	  def place_delete (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if p = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Place
	        p.attached_to.places.delete p if p.attached_to
	        $WORLD.unregister_object p
	        $WORLD.controller.create_message addr, "Place-Id: #{p.id} removed."
	      end
	    end
	  end
	  def item_create (addr, cmd, param)
	    i = MUD::Item.new
	    $WORLD.controller.create_message addr, "Item created. Id: #{i.id}."
	  end
	  def item_name (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if i = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Item
	        i.name = $2
	        $WORLD.controller.create_message addr, "Item-Id: #{i.id} name set: #{i.name}."
	      end
	    end
	  end
	  def item_info (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if i = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Item
	        $WORLD.controller.create_message addr, "Item-Id: #{i.id} has the following properties:%n#{i.info * "%n"}."
	      end
	    end
	  end
	  def item_desc (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if i = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Item
	        i.desc = $2
	        $WORLD.controller.create_message addr, "Item-Id: #{i.id} desc set: #{i.desc}."
	      end
	    end
	  end
	  def item_actionuse (addr, cmd, param)
	    if param =~ /^(\d+)\s(.+)$/
	      if i = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Item
	        i.actionuse = $2
	        $WORLD.controller.create_message addr, "Item-Id: #{i.id} action-use set: #{i.actionuse}."
	      end
	    end
	  end
	  def item_attach (addr, cmd, param)
	    if param =~ /^(\d+)\s(\d+)$/
	      if i = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Item and a = $WORLD.object_map[$2.to_i] and ($WORLD.object_map[$2.to_i].instance_of? MUD::Gridfield or $WORLD.object_map[$2.to_i].instance_of? MUD::Player)
	        i.attached_to.items.delete i if i.attached_to
	        i.attached_to = a
	        a.items.push i
	        $WORLD.controller.create_message addr, "Item-Id: #{i.id} attachment set to #{a.class}-Id: #{a.id}."
	      end
	    end
	  end
	  def item_delete (addr, cmd, param)
	    if param =~ /^(\d+)$/
	      if i = $WORLD.object_map[$1.to_i] and $WORLD.object_map[$1.to_i].instance_of? MUD::Item
	        i.attached_to.items.delete i if i.attached_to
	        $WORLD.unregister_object i
	        $WORLD.controller.create_message addr, "Item-Id: #{i.id} removed."
	      end
	    end
	  end
    def player_info (addr, cmd, param)
      p = $WORLD.UPROC.player_by_name param if param
      if p
        $WORLD.controller.create_message addr, p.info*"%n"
      else
        $WORLD.controller.create_message addr, "Player does not exist."
      end
	  end
    def shutdown (addr, cmd, param)
      $WORLD.UPROC.map_addr_player.each do |ad,user|
        $WORLD.controller.create_message ad, "Server is shutting down."
      end
      $WORLD.controller.create_message addr, "SPECIAL::SHUTDOWN"
	  end
  end
end
