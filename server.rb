require 'eventmachine'
require 'json'

class EchoServer < EM::Connection
  attr_accessor :username

  def self.clients
    @clients ||= []
  end

  def post_init
    puts "-- someone connected to the echo server!"
    add_client
  end

  def receive_data input
    p [self, input]

    data = JSON.parse(input)

    p data
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
      push_to_others(data[:message])
    end
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

