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

  def self.read
    file = File.open(path + self.file, "r")
    result = []
    file.each_line do |line|
      result << JSON.parse(line)
    end
    file.close

    result
  end
end

class Fireplace < EM::Connection
  attr_accessor :username

  def self.persistance(persistance_class)
    @@persistance_class = persistance_class
  end

  persistance Persistance

  def post_init
    @username = "Guest #{rand(999)}"
    add_client

    message = {command: "say", username: @username, message: "has entered the room"}

    @@persistance_class.read.each do |line|
      push_to_me(line)
    end

    push(message)

    log(message)
  end

  def receive_data input
    begin
      data = JSON.parse(input)
    rescue JSON::ParserError
      raise input.inspect
    end

    data = data.merge(username: username)

    p [self, data]

    log(data)

    case data["command"]
    when "set_username"
      old_username = @username
      @username = data["arguments"][0]
      if old_username
        say("#{old_username} changed name to #{@username}")
      else
        say("New user registered: #{@username}")
      end
    when "say"
      push(data)
    end
  end

  def say(what)
    push(command: "say", message: what, username: @username)
  end

  def log(data)
    @@persistance_class.write(data)
  end

  def add_client
    @@clients ||= []
    @@clients << self
  end

  def push(message)
    @@clients.each do |instance|
      instance.send_data(message.to_json)
    end
  end

  def push_to_me(message)
    send_data(message.to_json)
  end

  def send_data(data)
    super(data + "\n")
  end

end

EventMachine::run {
  EventMachine::start_server "127.0.0.1", 8081, Fireplace
  puts 'running echo server on 8081'
}

