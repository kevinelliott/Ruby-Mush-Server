#!/usr/bin/ruby

require 'net/telnet'
require 'thread'

class Benchmark
  def initialize
    @host = "mayumayu.mine.nu"
    @port = 4242
    @timeout = 30
    @prompt = /\n$/n
    @connection = nil
  end
  
  def connect
    @connection = Net::Telnet::new("Host" => @host, "Port" => @port, "Timeout" => @timeout, "Prompt" => @prompt)
  end
  
  def cmd (c)
    str = ""
    @connection.cmd(c) do |com|
      str += com
    end
    return str
  end
  
  def walk (d)
    str = ""
    @connection.cmd(d) do |c|
      str += c
    end
    @connection.waitfor("Timeout" => @timeout, "Prompt" => @prompt) do |c|
      str += c
    end
    return str
  end
  
  def time (func, str)
    tnow = Time.now.to_f
    self.method(func).call str
    return Time.now.to_f - tnow
  end
  
  def disconnect
    @connection.close
  end
end

mutex = Mutex.new
count = 1
arr = Array.new
for k in 0...40 do
  arr[k] = Thread.new {
    i = 0
    mutex.synchronize do
      i = count
      count += 1
    end
    sleep(0.5*count)
    starto = Time.now.to_f
    timed = Array.new
    b = Benchmark.new
    b.connect
    timed.push [b.time(:cmd, "register bot#{i} pass#{i}"), "register"]
    timed.push [b.time(:walk, "home"), "walk"]
    for j in 1..100 do
      timed.push [b.time(:walk, "field#{j}"), "walk"]
      sleep(3)
    end
    #puts timed
    
    avg = 0
    peak = 0
    low = 100
    timed.each do |a|
      avg += a[0]
      peak = a[0] if a[0] > peak
      low = a[0] if a[0] < low
    end
    puts "Results for i: #{i} ---[ entrynumber #{timed.length} , avg #{avg / timed.length} , peak #{peak} , low #{low} , total time used #{Time.now.to_f - starto} (slept 300) ]"
    b.disconnect
  }
end

arr.each do |t| t.join end
