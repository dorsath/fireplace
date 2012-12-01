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
      @out << "data: " + line + "\n\n"
    end
  end

end

class Client
  def initialize(out)
    @out = Out.new(out)
    @q = EM::Queue.new
    EM.run {


      EM.connect("127.0.0.1", 8081, Echo, @q, @out)
    }
  end

  def add_out(new_out)
    @out.add_out(new_out)
  end

  def send_message(message)
    @q.push(format_input(message).to_json)
  end

  def remove_out(out)
    @out.remove_out(out)
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

class Out
  def initialize(out)
    @outs = [out]
    @total = []
  end

  def outs
    @outs
  end

  def add_out(new_out)
    @outs << new_out
    @total.each do |line|
      new_out << line
    end
  end

  def remove_out(out)
    @outs.delete(out)
    @outs.each {|out| out << "data: Someone closed his browser\n\n"}
  end

  def << (data)
    @total << data
    @outs.each {|out| out << data}
  end
end



