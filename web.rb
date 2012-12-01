require 'sinatra'
require 'eventmachine'
require './client'

set :server, :thin
connections = {}

get '/' do
  haml :index
end

get '/stream' do
  content_type "text/event-stream"
  puts "connection made"

  stream(:keep_open) do |out|
    if connections[request.ip]
      connections[request.ip].add_out(out)
    else
      connections[request.ip] = Client.new(out)
    end

    out.callback {connections[request.ip].remove_out(out) }
  end
end

post "/speak" do

end

