require 'socket'

server = TCPServer.open("localhost", 8080)
loop do
  client = server.accept
  Thread.start(client) do |connection|
    loop do 
      message = connection.gets.chomp
      next if message.empty?
      puts message
      connection.puts message
    end
  end
end.join
