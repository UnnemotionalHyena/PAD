require 'socket'
require 'pry'

server           = TCPServer.open("localhost", 8080)
@connection_name = {}
loop do
  client = server.accept
  Thread.start(client) do |connection|
    connection.puts "Please enter your username to establish a connection..."
    loop do
      connection.puts "Username: "
      name = connection.gets.chomp.to_sym
      if name.empty?
        next
      end
      if @connection_name.values.include? name
        connection.puts "This username already exist"
        next
      else
        @connection_name[connection] = "@#{name}"
      end
      puts "Connection established #{@connection_name[connection]}"
      connection.puts "Connection established"
      break
    end
    # binding.pry
    loop do
      message = connection.gets.chomp
      next if message.empty?
      puts message
      if message.match?(/\@\w+/)
        reciver = message[/\@\w+/]
        if @connection_name.values.include? reciver
          @connection_name.key(reciver).puts message
          next
        end
      end
      @connection_name.each do |user_connection, name|
        next if user_connection = connection
        user_connection.puts message
      end
    end
  end
end.join
