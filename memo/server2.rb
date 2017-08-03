# A more usable server (serving multiple clients):

require 'socket'

port = ARGV[0]
server = TCPServer.new port
loop do
  Thread.start(server.accept) do |client|
    client.puts "Hello !"
    client.puts "Time is #{Time.now}"
    client.close
  end
end
