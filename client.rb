require 'socket'
require 'pry'

socket = TCPSocket.open( "localhost", 8080 )

connection_tread = Thread.new do
  loop do
    begin
      message = $stdin.gets.chomp
      socket.puts message
      if message.match?(/^ *!quit *$/)
        puts "good bye"
        socket.close
        exit
      end
    rescue IOError => e
      puts e
      socket.close
      exit
    end
  end
end

dialog_thread = Thread.new do
  loop do
    begin
      response = socket.gets.chomp
    rescue => error
      if error.is_a? NoMethodError
        puts "Server down"
        socket.close
        exit
      end
    end
    puts "#{response}"

    # if response =~ /quit session/
    #   socket.close
    #   exit
    # end
  end
end

connection_tread.run
dialog_thread.run

connection_tread.join
dialog_thread.join
