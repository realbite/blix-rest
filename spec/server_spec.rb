require 'spec_helper'
require 'test_controllers'

CONTENT_TYPE      = 'Content-Type'
CONTENT_TYPE_JSON = 'application/json'
CONTENT_TYPE_HTML = 'text/html'
CONTENT_TYPE_XML  = 'application/xml'
ACCEPT = "HTTP_ACCEPT"
    
module Blix::Rest
  
  describe Server do
    
    before(:all) do
      @app = Server.new
      @srv = Rack::MockRequest.new(@app)
    end
    
    it "should detect the format" do
      @app.get_format({}).should == nil
      @app.get_format({ACCEPT=>"application/json"}).should == :json
      @app.get_format({ACCEPT=>"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"}).should == :html
    end
   
    
  end
  
end