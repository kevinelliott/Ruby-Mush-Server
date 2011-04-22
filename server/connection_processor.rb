

class ConnectionProcessor
  
  # construct a new process
  # [param i:]    process num
  # [param rd:]   incoming pipe from intermediate
  # [param wr:]   outgoing pipe to intermediate
  # [param acc:]  socket acceptor to grab incoming connections
  # [param addr:] socket address for convenience
  def initialize (i, rd, wr, acc, addr)
    @id = i
    @running = true
    @read = rd
    @write = wr
    @acceptor = acc
    @address = addr
    @connections = Hash.new
    @queue = Hash.new
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
      
      # check incoming pipe from intermediate
      self.pipe_out
      
      for i in 0..@connections.to_a.length do
        # either try to accept new connection, or keep looping through accepted connections
        l = @connections.to_a.length
        if i < l
          # fetch connection details
          arr = @connections.to_a[i]
          socket = arr[1]
          addr = arr[0]
          
          # check pending messages from intermediate for connection and send all
          self.send_all addr
          
          # check for incoming messages from connection
          begin
            # fetch new message or exception
            msg = socket.recvfrom_nonblock $INC_BUFFER_MAX
            
            # if connection has more messages queued, recvfrom returns an array
            if msg.instance_of? Array
              # connection was closed unexpectedly? then throw exception
              if msg.length > 1 and msg[0].length == 0 and msg[1].length == 0
                raise Errno::ECONNRESET
              end
              
              # more messages need to be splitted, right-stripped and sent to outgoing pipe to intermediate
              arr = msg[0].split "\n"
              arr.each do |m|
                if self.parse_message_for_controlflags m
                  self.compute_message addr, m.rstrip
                  if $PING_BACK
                    socket.write "Ping-back: " + m.rstrip + "\r\n"
                    socket.flush
                  end
                end
              end
            # single message was returned (compute_message checks for multiple messages, just in case) (successful right-strip)
            else
              if self.parse_message_for_controlflags m
                self.compute_message addr, msg[0].rstrip
                if $PING_BACK
                  socket.write "Ping: " + msg[0].rstrip + "\r\n"
                  socket.flush
                end
              end
            end
          # rescue the socket was empty
          rescue Errno::EAGAIN, Errno::EWOULDBLOCK
          # rescue writing to closed pipe or connection was closed
          rescue Errno::ECONNRESET, Errno::EPIPE, Errno::EIO, Errno::EINTR, Errno::EFAULT, Errno::ENOTCONN, Errno::ETIMEDOUT, Errno::EBADF, Errno::EINVAL, Errno::ENOBUFS, Errno::ENOMEM, Errno::ENOSR, Errno::ENOTSOCK, Errno::EOPNOTSUPP, IOError
            self.close addr
          end
          # loop to next connection
          i += 1
        else
          # reset counter, last connection is past
          i = 0
          # check for pending new connection
          begin
            # accept new connection or exception
            socket, addr = @acceptor.accept_nonblock
            self.accept socket, addr
          # no new connection was detected
          rescue Errno::EAGAIN
          end
        end
      end
      # how long did the processing take?
      difference = Time.now.to_f - tnow
      
      break if not @running
    end
  end
  
  # incoming socket connection: accept
  # [param socket:]   socket descriptor for new connection
  # [param addr:]     socket string representing new connection
  def accept (socket, addr)
    @connections[addr] = socket
    @queue[addr] = Array.new
    self.compute_message addr, "SPECIAL::CREATE"
    puts "Connection accepted on processor id: #{@id}." if $DO_DEBUG
  end
  
  # incoming socket connection: close
  # [param addr:]     socket string representing the connection
  def close (addr)
    if not @connections.has_key? addr
      return
    end
    socket = @connections[addr]
    @connections.delete addr
    @queue.delete addr
    self.compute_message addr, "SPECIAL::DELETE"
    socket.close
    puts "Connection closed on processor id: #{@id}." if $DO_DEBUG
  end
  
  # intermediate sends a message for connection
  # [param addr:]     socket string representing the connection
  # [param msg:]      message to be passed on (successful right-strip)
  def queue (addr, msg)
    if @queue.has_key? addr
      @queue[addr].push msg
    end
  end
  
  # working off the first message from the intermediate for a connection
  # [param addr:]     socket string representing the connection
  # [returns:]        nil or the first item
  def dequeue (addr)
    elem = nil
    elem = @queue[addr][0] if not self.queue_empty? addr
    @queue[addr].delete_at 0
    return elem
  end
  
  # checking if any messages from the intermediate are available for a connection
  # [param addr:]     socket string representing the connection
  # [returns:]        true if queue is empty
  def queue_empty? (addr)
    return @queue[addr].empty?
  end
  
  # working off all messages from the intermediate for a connection (add a newline)
  # [param addr:]     socket string representing the connection
  def send_all (addr)
    socket = @connections[addr]
    begin
      while not self.queue_empty? addr do
        msg = self.dequeue(addr)
        msg = self.parse_controls msg
        socket.write msg + "\r\n"
        socket.flush
      end
    rescue Errno::ECONNRESET, Errno::EPIPE
      self.close addr
    end
  end
  
  # read the incoming pipe from the intermediate and queue new messages
  def pipe_out
    while 1 do
      begin
        # construction similar to non-blocking eof
        # each gets fetches one message only
        m = @read.read_nonblock 1
        n = @read.gets
        m = m + n.rstrip
        arr = m.split '@#$#@'
        addr = arr[0]
        arr.delete_at 0
        m = arr * ""
        if m.downcase =~ /^special::close_socket/
          self.close addr
        elsif m == "SPECIAL::SHUTDOWN"
          @running = false
        else
          self.queue addr, m
        end
      # rescue if pipe is empty or not ready
      rescue Errno::EAGAIN
        break
      # rescue if pipe is eof
      rescue EOFError
        puts "Eoferror" if $DO_DEBUG
        break
      end
    end
  end
  
  # messages from connection arrive and are passed on one by one to outgoing pipe to intermediate (add a newline)
  # [param addr:]     socket string representing the connection
  # [param msg:]      message (successful right-strip) consisting of one or more single messages
  def compute_message (addr, msg)
    arr = msg.split "\n"
    arr.each do |m|
      @write.write addr + '@#$#@' + m + "\n"
      @write.flush
    end
  end
  
  # messages starting with certain words are filtered to ensure server control
  # [param msg:]    single message for checking
  # [returns:]      true if message is okay
  def parse_message_for_controlflags (msg)
    if msg.downcase =~ /^special/
      return false
    else
      return true
    end
  end
  
  # messages including special characters are substituted with a replacement, i.e. %t is \t
  # [param msg:]    unparsed message
  # [returns:]      substituted message
  def parse_controls (msg)
    msg = msg.gsub "%n", "\r\n"
    msg = msg.gsub "%t", "\t"
    msg = msg.gsub "%=", "="
    return msg
  end
end

