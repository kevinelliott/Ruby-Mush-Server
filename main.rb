#!/usr/bin/ruby

require 'time'
require 'socket'
require 'globals'
require 'support'
require 'server/connection_processor'
require 'server/data_intermediate'

require 'mud/controller'
require 'mud/world'
require 'mud/message_interface'
require 'mud/message_processor'
require 'mud/user_processor'
require 'mud/global_time'
require 'mud/time_specifics'
require 'mud/weather'
require 'mud/celestial_body'
require 'mud/object'
require 'mud/static'
require 'mud/doorkey'
require 'mud/grid_cloud'
require 'mud/place'
require 'mud/gridfield'
require 'mud/connector'
require 'mud/dynamic'
require 'mud/movable'
require 'mud/player'
require 'mud/detachable'
require 'mud/item'

### initialize server

# init socket
acceptor = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
address = Socket.pack_sockaddr_in($PORT, $HOST)
acceptor.bind(address)
acceptor.listen($MAX_BACKLOG)

# install traps to exit socket
trap('EXIT') { acceptor.close }
trap('INT') { acceptor.close }

# init pipes for inter-process communication
#connector pipe
rd_conn = Array.new
wr_conn = Array.new
#intermediate pipe
rd_inter = Array.new
wr_inter = Array.new
#connect pipes properly
for i in 0...$NUM_PROCS do
  rd_conn[i], wr_inter[i] = IO.pipe
  rd_inter[i], wr_conn[i] = IO.pipe
end
#controller to intermediate pipe
rd_inter2, wr_cont = IO.pipe
#intermediate to controller pipe
rd_cont, wr_inter2 = IO.pipe

### fork children
for i in 0..($NUM_PROCS) do
  fork do
    # child acting as intermediate
    if i == 0
      di = DataIntermediate.new rd_inter, wr_inter, rd_inter2, wr_inter2
      di.pipeline
    # child running the game-world
    #elsif i == 1
    #  ct = MUD::Controller.new rd_cont, wr_cont
    #  ct.pipeline
    # children accepting connections
    else
      cp = ConnectionProcessor.new i - 1, rd_conn[i - 1], wr_conn[i - 1], acceptor, address
      cp.pipeline
    end
  end
end

puts "Server initialized." if $DO_DEBUG

# run the game-world
ct = MUD::Controller.new rd_cont, wr_cont
ct.pipeline

### wait for processes to end
puts "Waiting for processes...."
Process.waitall

### finishing up
puts "Closing socket...."
acceptor.close

puts "Shutdown."

