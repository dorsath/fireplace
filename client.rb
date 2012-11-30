require 'eventmachine'
require 'json'

class Echo < EM::Connection
  attr_reader :queue

  def initialize(q)
    @queue = q

    cb = Proc.new do |msg|
      send_data(msg)
      q.pop &cb
    end

    q.pop &cb
  end

  def post_init
    # send_data('Hello')
  end

  def receive_data(input)
    input.split("\n").each do |line|
      process_command(JSON.parse(line))
    end
  end

  def process_command(data)
    case data["command"]
    when "say"
      print "#{data["username"]}: #{data["message"]}\n"
    else 
      print "unknown command: #{data}"
    end
  end

end

class KeyboardHandler < EM::Connection
  include EM::Protocols::LineText2

  attr_reader :queue

  def initialize(q)
    @queue = q
  end

  def receive_line(data)

    @queue.push(format_input(data).to_json)
  end

  def format_input(data)
    if data[0] == "/"
      command, *arguments = data[1..-1].split(/ /)
      {command: command, arguments: arguments}
    else
      {command: "say", message: data}
    end
  end


end

EM.run {
  q = EM::Queue.new

  EM.connect("194.111.30.153", 8081, Echo, q)
  EM.open_keyboard(KeyboardHandler, q)
}
