require 'socket'
require './lib/lib'

Thread.abort_on_exception = true

puts "Starting server on port 2000 with pid #{Process.pid}"

server = TCPServer.open(2000)

$client_handlers = {}
$messages        = []

def create_client_handler(nickname, socket)
  Fiber.new do
    last_write = Time.now

    loop do
      state = Fiber.yield

      if state == :readable
        # Read a message from the socket
        incoming = read_line_from(socket)

        # If the message is nil the client disconnected
        if incoming.nil?
          puts "Disconnected #{nickname}"
          # Remove the client from storage
          $client_handlers.delete(socket)
          # Exit fiber by breaking the loop
          break
        end

        # All good, add it to the list to write
        $messages.push(
          :time     => Time.now,
          :nickname => nickname,
          :text     => incoming
        )
      elsif state == :writable
        # Write messages to the socket
        get_messages_to_send(nickname, $messages, last_write).each do |message|
          socket.puts "#{message[:nickname]}: #{message[:text]}"
        end

        last_write = Time.now
      end
    end
  end
end

# Our event loop
loop do
  # Step 1: See if we have any new incoming connections
  begin
    socket                   = server.accept_nonblock
    nickname                 = socket.gets.chomp
    $client_handlers[socket] = create_client_handler(nickname, socket)
    puts "Accepted connection from #{nickname}"
  rescue IO::WaitReadable, Errno::EINTR
    # No new incoming connections at the moment
  end

  # Step 2: Ask the OS to inform us when a connection is ready, wait for 10ms for this to happen
  # A "real" event loop system would register interest instead of calling this every tick
  readable, writable = IO.select(
    $client_handlers.keys,
    $client_handlers.keys,
    $client_handlers.keys,
    0.01
  )

  # Step 3: See if any of our connections are readable and trigger the client
  if readable
    readable.each do |ready_socket|
      # Get the client from storage
      client = $client_handlers[ready_socket]

      client.resume(:readable)
    end
  end

  # Step 4: See if any of our connections are writable and trigger the client
  if writable
    writable.each do |ready_socket|
      # Get the client from storage
      client = $client_handlers[ready_socket]
      next unless client

      client.resume(:writable)
    end
  end

  # Done! Onto the next tick of the event loop
end
