require 'blix/rest'

class InfoController < Blix::Rest::Controller
     get '/info' do
          "hello"
     end
end

run Blix::Rest::Server.new
