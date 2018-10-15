require 'socket'
require 'base64'
require 'pry'

socket = TCPSocket.open( "localhost", 8080 )

connection_tread = Thread.new do
  loop do
    begin
      message = $stdin.gets.chomp
      if message[/\$file/i]
        next unless message[/\@.*?( |$)/]
        reciever  = message[/\@.*?( |$)/].strip
        f_message = message.gsub(/\@.*?( |$)/, "")
        file_path = f_message.gsub(/\$file/, "").strip
        unless File.file?(file_path)
          if file_path.include?("\n")
            puts "delete witespaces in the file names"
            next
          end
          puts "file unexisting"
          next
        end
        file = File.open(file_path, "r")
        fileContent = file.read
        socket.puts(reciever + " $file " + Base64.encode64(File.basename(file_path) + "$$$" + fileContent).delete("\n"))
        next
      end
      socket.puts message
      if message.match?(/^ *!quit *$/)
        puts "good bye"
        socket.close
        exit
      end
    rescue error
      puts error
      socket.close
      exit
    end
  end
end

dialog_thread = Thread.new do
  loop do
    begin
      response = socket.gets.chomp
      if response[/\$file /]
        file_base64 = response.gsub(/.*\$file /, "")
        file_str    = Base64.decode64(file_base64).split("$$$")

        Dir.mkdir("Downloads") unless File.exists?("Downloads")
        file = File.open("Downloads/" + file_str.first, "w")
        file.print file_str.last
        file.close
        puts "#{response[/\@.*? /]}#{file_str.first}"
        next
      end
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
