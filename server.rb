require 'socket'
require 'pry'

class Server
  def initialize
    @server          = TCPServer.open("localhost", 8080)
    @connection_name = {}
    @info            = {}
    unless File.file?("connections/con.txt")
      Dir.mkdir("connections")
      File.new("connections/con.txt", "w").close
    end
    unless File.exist?("pending_messages")
      Dir.mkdir("pending_messages")
    end
    unless File.exist?("messages")
      Dir.mkdir("messages")
    end
  end

  def start_server
    loop do
      client = @server.accept
      Thread.start(client) do |connection|
        login_user(connection)
        message_router(connection)
      end
    end.join
  end

private

  def login_user(connection)
    connection.puts "Please enter your username to establish a connection..."
    loop do
      connection.puts "Username: "
      name = connection.gets.chomp.to_sym
      if name.empty?
        next
      end
      name = "@#{name}"
      if @connection_name.values.include? name
        connection.puts "This username already exist"
        next
      end

      connection.puts "File Format: "
      file_format = connection.gets.chomp.to_sym
      if file_format.empty? || !file_format.match?(/JSON|CSV|XML/i)
        file_format = "json"
      end

      @connection_name[connection] = name
      @info[name]                  = {
        file_format: file_format,
        last_login:  Time.now
      }

      puts "Connection established #{@connection_name[connection]}"
      save_connection(name)
      connection.puts "Connection established"
      puts_all_pendings(connection, name)
      break
    end
  end

  def message_router(connection)
    loop do
      begin
        message = connection.gets.chomp
      rescue => error
        @connection_name.delete(connection) if error.is_a? NoMethodError
        puts "ERROR: #{@connection_name} deleted"
        return
      end
      next if message.empty?
      puts message
      save_conversation(@connection_name[connection], message)
      if message.match?(/\@\w+/)
        reciever  = message[/\@\w+/]
        f_message = "#{@connection_name[connection]}: #{message.gsub(/\@.*?( |$)/, "")}"

        if @connection_name.values.include? reciever
          next if @connection_name.key(reciever) == connection
          @connection_name.key(reciever).puts f_message
          save_conversation(reciever, f_message)
        elsif connection_exist?(reciever)
          connection.puts("User #{reciever} offline")
          add_pendings(reciever, f_message)
        else
          connection.puts("User #{reciever} inexistent")
        end

        next
      elsif message.match?(/^ *!quit *$/)
        @connection_name.delete(connection)
        connection.close

        return
      end

      f_message = "#{@connection_name[connection]}: #{message}"
      @connection_name.each do |user_connection, name|
        next if user_connection == connection
        user_connection.puts f_message
        save_conversation(name, f_message)
      end
    rescue => error
      binding.pry
    end
  end

  def save_connection(name)
    file = File.open("connections/con.txt", "a+")
    file.each do |line|
      return if line == "#{name}\n"
    end
    file.write("#{name}\n")
    file.close
  end

  def connection_exist?(name)
    file = File.open("connections/con.txt", "r")
    file.each do |line|
      if line == "#{name}\n"
        file.close
        return true
      end
    end
    file.close
    false
  end

  def add_pendings(name, message)
    file = File.open("pending_messages/messages_#{name}.txt", "a")
    file.write("#{message}\n")
    file.close
  end

  def puts_all_pendings(connection, name)
    return unless File.file?("pending_messages/messages_#{name}.txt")
    file = File.open("pending_messages/messages_#{name}.txt", "r+")
    file.each do |line|
      connection.puts(line.gsub("\n", ""))
    end
    file.close
    file = File.open("pending_messages/messages_#{name}.txt", "w")
    file.close
  end
  def save_conversation(name, message)
    name.gsub("\n", "")
    file = File.open("messages/messages_#{name}.txt", "a")
    file.write("#{message}\n")
    file.close
  end
end

server = Server.new()
server.start_server
