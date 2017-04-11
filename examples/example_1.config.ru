# rackup -p3000 examples/example_1.config.ru
#
$:.unshift('lib')

require 'blix/rest'

class HomeController < Blix::Rest::Controller

     get '/hello', :accept=>[:html,:json] do
        if format == :json
          {"message"=>"hello world"}
        else
         "<h1>hello world</h1>"
        end
     end
end

run Blix::Rest::Server.new