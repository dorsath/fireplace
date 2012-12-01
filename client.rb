require 'eventmachine'
require 'json'

class Echo < EM::Connection
  attr_reader :queue

  def initialize(q, out)
    @queue = q
    @out = out
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
      @out.outs.each {|out| out << "data: #{data["username"]}: #{data["message"]}\n\n"}
    else
      @out.outs.each {|out| out << "data: #{data["username"]}: #{data["message"]}\n\n"}
    end
  end

end

class Client
  def initialize(out)
    @out = Out.new(out)
    EM.run {
      q = EM::Queue.new

      EM.connect("127.0.0.1", 8081, Echo, q, @out)
    }
  end

  def add_out(new_out)
    @out.add_out(new_out)
  end

  def remove_out(out)
    @out.remove_out(out)
  end
end

class Out
  def initialize(out)
    @outs = [out]
  end

  def outs
    @outs
  end

  def add_out(new_out)
    @outs << new_out
  end

  def remove_out(out)
    @outs.delete(out)
    @outs.each {|out| out << "data: Someone close his browser\n\n"}
  end

end



