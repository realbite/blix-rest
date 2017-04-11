require 'spec_helper'

module Realbite::Rest
  
  
  
  describe Service do
    
    before(:each) do
      WebFrameService.configure :login=>'foo', :secret=>'mysecret'
    end
    
    it "should create a service object" do
      s = Service.new("testservice")
      s.name.should == "testservice"
    end
    
    it "should auto configure a service object" do
      WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(200, '{"data":{"_type":"service","id":1234, "name":"testservice", "url":"https://myservice.com"}}'))
      s = Service.new("testservice")
      s.auto_configure
      s.url.should == "https://myservice.com"
    end
    
    it "should manually configure a service object" do
      s = Service.new("testservice")
      s.configure(:url=>'http://example.com')
      s.url.should =='http://example.com'
    end
    
    it "should add a token to a request" do
      s = Service.new("testservice")
      s.configure(:url=>'http://example.com')
      s.token.should == nil
      WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(200, '{"data":{"token":"qwerty"}}'))
      s.server.stub(:request).and_return(DummyResponse.new(200, '{"data":"welcome"}'))
      s.get('info')
      s.token.should == "qwerty"
    end
    
    
    it "should refresh the token if it is rejected by the service" do
      s = Service.new("testservice")
      s.configure(:url=>'http://example.com')
      s.token.should == nil
      counter1 = 1
      WebFrameService.instance.server.stub(:request) do |r|
        counter1 +=1
        if counter1 == 2
          DummyResponse.new(200, '{"data":{"token":"qwerty"}}') 
        else
          DummyResponse.new(200, '{"data":{"token":"asdef"}}')
        end
      end
      counter2 = 1
      s.server.stub(:request) do |r|
        counter2 +=1
        if counter2 == 2
          DummyResponse.new(406, '{"error":"token expired"}')
        else
          DummyResponse.new(200, '{"data":"welcome"}')
          end
      end
     
      #s.server.stub(:request)
      s.get('/info').should == {"data"=>"welcome"}
      s.token.should == "asdef"
    end
  end
  
  
  
end