# Listen for incoming messages on the master's reader and write
# every incoming message to all forked processes
def write_incoming_messages_to_child_processes(master_reader, client_writers)
  # 这就涉及到所谓的 **线程安全** 的问题
  # 实际此方法只是在启动 server 时候调用了一次, 而实际上在第一次唯一一次能看见
  # 调用的时候, client_writers 并没有任何值.
  # 而之后是在每次添加一个连接客户端之后才会添加.
  # 然后在下吗 master_reader.gets 会监视输入, 当有输入的时候就会
  # 遍历 clients 然后发送消息.
  Thread.new do
    while incoming = master_reader.gets
      # puts "write_incoming_messages_to_child_processes #{master_reader}, #{client_writers}"
      client_writers.each do |writer|
        writer.puts incoming
      end
    end
  end
end

# Run a thread that listens to incoming messages from the master process and
# writes these back to the client
def write_incoming_messages_to_client(nickname, client_reader, socket)
  Thread.new do
    # 监视 client 输入, 然后将消息 push 到服务端.
    while incoming = client_reader.gets
      unless incoming.start_with?(nickname)
        puts incoming
        socket.puts incoming
      end
    end
  end
end

# Read a line and strip any newlines
def read_line_from(socket)
  if read = socket.gets
    read.chomp
  end
end

def get_messages_to_send(nickname, messages, sent_until)
  [].tap do |out|
    messages.reverse_each do |message|
      # Once we're behind sent_until everything has already been sent
      break if message[:time] < sent_until
      # Don't send if we typed this ourselves
      next if message[:nickname] == nickname

      out.push(message)
    end
  end
end
