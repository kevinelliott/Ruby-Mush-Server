
module MUD
  class Controller
    
    # construct a new controller
    # [param rd:]       incoming pipe from intermediate
    # [param wr:]       outgoing pipe to intermediate
    def initialize (rd, wr)
      @running = true
      @read = rd
      @write = wr
      
      # construct the world and environmentals
      $WORLD = MUD::World.new self
      @gtime = MUD::GlobalTime.new
      $WORLD.globaltime = @gtime
      self.load_world
      puts "World is loaded." if $DO_DEBUG
    end
    
    # endless pipeline
    def pipeline
	  puts "Initializing Controller Pipeline." if $DO_DEBUG
      difference = 0.0
      while 1 do
        sleep = $TOTAL_SLEEP - difference
        sleep = 0.0 if sleep < 0.0
        sleeper = IO.popen "sleep #{sleep}"
        Process.wait
        sleeper.close
        
        # take timestamp
        tnow = Time.now.to_f
        
        # garbage collect
        if Time.now.to_i % 60 == 0
          GC.start
        end
        
        # handle the world situation (temp)
        # celestial bodies
        for i in 0...@gtime.timespecs.length
          #@gtime.timespecs[i].compute_time * " --- "
          #@gtime.timespecs[i].compute_celestial_bodies * " --- "
          #@gtime.timespecs[i].list_celestial_bodies * " --- "
        end
        tcele = Time.now.to_f - tnow
        #puts "Time to compute time and celestial bodies #{tcele}"
        # gridclouds - weather
        for i in 0...$WORLD.gridclouds.length
          $WORLD.gridclouds[i].compute_weather
        end
        tweather = Time.now.to_f - tnow - tcele
        #puts "Time to compute weather #{tweather}"
        
        # check incoming pipe from the intermediate (successful right-strip)
        while 1 do
          begin
            m = @read.read_nonblock 1
            n = @read.gets
            m = m + n.rstrip
            arr = m.split '@#$#@'
            addr = arr[0]
            arr.delete_at 0
            m = arr * ""
            self.computing_message addr, m
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
            break
          rescue EOFError
            puts "Eoferror" if $DO_DEBUG
            break
          end
        end
        
        # how long did the processing take?
        difference = Time.now.to_f - tnow
        puts "skip beat at #{Time.now.to_f} getting #{$TOTAL_SLEEP - difference}" if $TOTAL_SLEEP - difference < 0 and $DO_DEBUG
        break if not @running
      end
    end
    
    # pass incoming message on to MessageInterface
    # [param addr:]       socket string representing the connection
    # [param msg:]        incoming message
    def computing_message (addr, msg)
      $WORLD.MI.incoming addr, msg
      #rmsg = $WORLD.MI.incoming addr, msg
      #self.create_message addr, msg + " (#{rmsg})" if not $WORLD.MI.is_special? msg and rmsg
    end
    
    # create a message to be sent to the intermediate
    # [param addr:]       socket string representing the connection
    # [param msg:]        outgoing message
    def create_message (addr, msg)
      if msg == "SPECIAL::SHUTDOWN"
        @running = false
      end
      @write.write addr + '@#$#@' + msg + "\n"
      @write.flush
    end
    
    # this is temporary (create the world as you know it...)
    def load_world
      default_tspecs = MUD::TimeSpecifics.new 2, 3, 1, ['Eins', 'Zwei'], 1000
      @gtime.default_spec = default_tspecs
      weather1 = MUD::Weather.new 10, 20, 30
      gridcloud1 = MUD::GridCloud.new
      $WORLD.gridclouds.push gridcloud1
      gridcloud1.weather = weather1
      sun = MUD::CelestialBody.new "Sol", 'n', 1, 50, 25, true, nil, nil
      moon = MUD::CelestialBody.new "Quark", 'w', 4, 50, 75, false, 2, ["Phase 1", "Phase 2"]
      default_tspecs.register_celestial sun
      default_tspecs.register_celestial moon
      gfield1 = MUD::Gridfield.new
      gfield1.name = "Home field"
      gfield1.desc = "The home screen, please do not touch anything! Omg and if you do, the almighty bumblebee will smack you in the face. Hell yaaarrrr!!"
      gfield1.rentable = true
      gfield2 = MUD::Gridfield.new
      gfield2.name = "Registration field"
      gfield2.desc = "Register Screen, create your character here!"
      gconn1 = MUD::Connector.new
      gconn1.name = "Home"
      gconn1.grid1 = gfield2.id
      gconn1.grid2 = gfield1.id
      gconn1.is_two_way = false
      gfield1.connectors.push gconn1
      gfield2.connectors.push gconn1
      gfield1.cloud = gridcloud1
	    gfield2.cloud = gridcloud1
	    gridcloud1.register_field gfield1
	    gridcloud1.register_field gfield2
	    
	    last = gfield1
	    for j in 1..100 do
	      nfield = MUD::Gridfield.new
	      nfield.name = "field#{j}"
	      nfield.desc = "This is the field number #{j}. Please hold the line."
	      nconn = MUD::Connector.new
	      nconn.name = "field#{j}"
	      nconn.name_opposite = "field#{j-1}" if j > 1
	      nconn.name_opposite = "Home" if j == 1
	      nconn.grid1 = last.id
	      nconn.grid2 = nfield.id
	      nconn.is_two_way = true
	      last.connectors.push nconn
	      nfield.connectors.push nconn
	      nfield.cloud = gridcloud1
	      gridcloud1.register_field nfield
	      last = nfield
	    end
	    
	    
	    place1 = MUD::Place.new
	    place1.attached_to = gfield1
	    gfield1.places.push place1
	    place1.name = "lol-line"
	    place1.desc = "This is my lol-line."
	    place1.actionenter = "%1 stands at the back of the lol-line."
	    place1.actionleave = "%1 leaves the lol-line."
	    place1.actionreply = "Currently the lol-line status is %1."
	    place1.space = 1
	    place2 = MUD::Place.new
	    place2.attached_to = gfield1
	    gfield1.places.push place2
	    place2.name = "pew pew"
	    place2.desc = "Effing lineline."
	    place2.actionenter = "%1 stands at the back of the pew."
	    place2.actionleave = "%1 leaves the pew."
	    place2.actionreply = "Currently the pew status is %1."
	    place2.space = 1
	    item1 = MUD::Item.new
	    item1.name = "Obfuscator"
	    item1.desc = "Obfuscating my ass."
	    item1.actionuse = "Obfuscating %1's asses."
	    item1.attached_to = gfield1
	    gfield1.items.push item1
      $WORLD.home_grid_field = gfield1
      $WORLD.register_grid_field = gfield2
    end
  end
end
