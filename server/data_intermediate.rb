

class DataIntermediate

  # construct a new intermediate
  # [param rd:]     incoming pipe-array from processors
  # [param wr:]     outgoing pipe-array to processors
  # [param rd2:]    incoming pipe from controller
  # [param wr2:]    outgoing pipe to controller
  def initialize (rd, wr, rd2, wr2)
    @running = true
    @read = rd
    @write = wr
    @cread = rd2
    @cwrite = wr2
    @map_id_to_addr = Hash.new
  end
  
  # endless pipeline
  def pipeline
    difference = 0.0
    while 1 do
      sleep = $TOTAL_SLEEP - difference
      sleep = 0.0 if sleep < 0.0
      sleeper = IO.popen "sleep #{sleep}"
      Process.wait
      sleeper.close
      
      # take timestamp
      tnow = Time.now.to_f
      
      # check incoming pipes from processors
      self.pipe_out
      
      # check incoming pipes from controller
      self.pipe_out_c
      
      # how long did the processing take?
      difference = Time.now.to_f - tnow
      
      break if not @running
    end
  end
  
  # read the incoming pipes from the processors and pass them along (successful right-strip)
  def pipe_out
    for i in 0...@read.length do
      while 1 do
        begin
          m = @read[i].read_nonblock 1
          n = @read[i].gets
          m = m + n.rstrip
          arr = m.split '@#$#@'
          addr = arr[0]
          arr.delete_at 0
          m = arr * ""
          self.pass_to_controller addr, m if parse_message_from_processor i, addr, m
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          break
        rescue EOFError
          puts "Eoferror" if $DO_DEBUG
          break
        end
      end
    end
  end
  
  # read the incoming pipe from the controller and pass it along (successful right-strip)
  def pipe_out_c
    while 1 do
      begin
        m = @cread.read_nonblock 1
        n = @cread.gets
        m = m + n.rstrip
        arr = m.split '@#$#@'
        addr = arr[0]
        arr.delete_at 0
        m = arr * ""
        if m == "SPECIAL::SHUTDOWN"
          for i in 0...@write.length
            self.pass_to_processor(i, addr, m)
          end
          @running = false
        elsif self.registered? addr
          i = @map_id_to_addr[addr]
          self.pass_to_processor i, addr, m
        else
          self.pass_to_controller addr, "SPECIAL::DELETE"
        end
      rescue Errno::EAGAIN, Errno::EWOULDBLOCK
        break
      rescue EOFError
        puts "Eoferror" if $DO_DEBUG
        break
      end
    end
  end
  
  # pass a message into a pipe to a processor (add a newline)
  # [param i:]      processor id
  # [param addr:]   socket string representing the connection
  # [param m:]      consisting of exactly one message (right-stripped)
  def pass_to_processor (i, addr, m)
    @write[i].write addr + '@#$#@' + m + "\n"
    @write[i].flush
  end
  
  # pass a message into the pipe to the controller (add a newline)
  # [param addr:]   socket string representing the connection
  # [param m:]      consisting of exactly one message (right-stripped)
  def pass_to_controller (addr, m)
    @cwrite.write addr + '@#$#@' + m + "\n"
    @cwrite.flush
  end
  
  # check if a socket address is registered to a processor id
  # [param addr:]   socket string representing the connection
  # [returns:]      true if address is registered
  def registered? (addr)
    return @map_id_to_addr.has_key? addr
  end
  
  # register a socket address to a processor
  # [param i:]      processor id
  # [param addr:]   socket string representing the connection
  def register (i, addr)
    @map_id_to_addr[addr] = i
  end
  
  # unregister a socket address to a processor
  # [param addr:]   socket string representing the connection
  def unregister (addr)
    @map_id_to_addr.delete addr
  end
  
  # returns if message should be passed along to controller (look for special tags)
  # [param i:]      processor id
  # [param addr:]   socket string representing the connection
  # [param m:]      message to be passed to the controller
  # [returns:]      true if message should be passed on
  def parse_message_from_processor (i, addr, m)
    if m =~ /^SPECIAL::CREATE/
      self.register i, addr if not self.registered? addr
      return false
    elsif not self.registered? addr
      return false
    else
      if m =~ /^SPECIAL::DELETE/
        self.unregister addr
      end
      return true
    end
  end
end

