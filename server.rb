require 'eventmachine'
require 'json'
require 'fileutils'

class Persistance
  attr_reader :path, :file

  def self.check_okay
    unless File.exist?(path+file)
      Dir.mkdir(path) unless File.directory?(path)
      FileUtils.touch(path+file)
    end
  end

  def self.path
    "./data/"
  end

  def self.file
    "messages.log"
  end


  check_okay

  def self.write(string)

    File.open(path + file, "a") do |file|
      file.write(string.to_json+"\n")
    end
  end
end

class EchoServer < EM::Connection
  attr_accessor :username
  
  def self.persistance(persistance_class)
    @@persistance_class = persistance_class
  end

  persistance Persistance

  def post_init
    @username = "Guest #{rand(0..999)}"
    add_client

    message = "#{@username} connected to the echo server!"

    log(message: message)
    push_to_everyone(message)
  end

  def receive_data input
    begin
      data = JSON.parse(input)
    rescue JSON::ParserError
      raise input.inspect
    end

    p [self, data]

    log(data)

    case data["command"]
    when "set_username"
      old_username = @username
      @username = data["arguments"][0]
      if old_username
        push_to_everyone("#{old_username} changed name to #{@username}")
      else
        push_to_everyone("New user registered: #{@username}")
      end
    when "say"
      push_to_others("#{@username}: #{data["message"]}")
    end
  end

  def log(data)
    @@persistance_class.write(data.merge(username: username))
  end

  def add_client
    @@clients ||= []
    @@clients << self
  end

  def push_to_everyone(data)
    @@clients.each do |instance|
      instance.send_data(data)
    end
  end

  def push_to_others(data)
    @@clients.reject { |c| c == self }.each do |instance|
      instance.send_data(data)
    end
  end

end

EventMachine::run {
  EventMachine::start_server "127.0.0.1", 8081, EchoServer
  puts 'running echo server on 8081'
}

