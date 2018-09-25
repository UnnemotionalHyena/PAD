require 'socket'

socket = TCPSocket.open( "localhost", 8080 )

connection_tread = Thread.new do
  loop do
    begin
      message = $stdin.gets.chomp
      socket.puts message
    rescue IOError => e
      puts e
      socket.close
      exit
    end
  end
end

dialog_thread = Thread.new do
  loop do
    response = socket.gets.chomp
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
