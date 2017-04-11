$:.unshift 'lib'

# require all our gems here

require 'bundler'
Bundler.require(:default, :test)

# require our application here

require 'blix/rest'

# configure rspec


  

RSpec.configure do  |c|
  
  c.expect_with :rspec do |oc|
    oc.syntax = [:should, :expect]
  end
  
  c.before(:all) do
    #Blix::WebFrame::Database.configure(:host=>'localhost', :database=>'webframe_test')
    @_app = Blix::Rest::Server.new
    @_srv = Rack::MockRequest.new(@_app)
  end
  c.before(:each) do
    Blix::Rest::RequestMapper.set_path_root(nil)
  end
end

# add some test helpers
TYPE_JSON = "application/json"

class DummyResponse
  attr_accessor :body
  attr_accessor :code
  attr_accessor :code_type
  attr_accessor :content_type
  attr_accessor :message
  def initialize(code,body=nil)
    @code = code
    @body = body
    @code_type =  Net::HTTPResponse::CODE_TO_OBJ[code.to_s]
    @content_type = "application/json"
  end
  
  def status
    code
  end
  
  def reason
    message
  end
end

module RequestHelpers
  
  
  
  class Response
    
    def initialize(resp)
      @resp = resp
      @h  = MultiJson.load(@resp.body) || {}
    end
    
    def [](k)
      @h[k]
    end
    
    def data
      @h["data"]
    end
    
    def error
      @h["error"]
    end
    
    def status
      @resp.status.to_i
    end
    
    def header
      @resp.header || {}
    end
    
    def content_type
      header["Content-Type"]
    end
    
    def inspect
      @resp.inspect
    end
    
  end
  
  def server_get path,params={}
    resp = @_srv.get(path, params) 
    return Response.new(resp)
  end
  
end