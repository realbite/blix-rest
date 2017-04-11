require 'spec_helper'

module Blix::Rest
  
  
  describe RemoteService do
    
    it "should create a new object" do
      s = RemoteService.new
      s.url.should == nil
      s = RemoteService.new(:url=>'http://example.com')
      s.url.should == 'http://example.com'
      s.prefix.should == nil
    end
    
    it "should configure the object" do
      s = RemoteService.new
      s.configure(:url=>'http://example.com',:prefix=>"/xxx")
      s.url.should == 'http://example.com'
      s.prefix.should == "/xxx"
    end
    
#    it "should have a server" do
#      r = RemoteService.new(:url=>'http://example.com')
#      s = r.server
#      s.address.should == "example.com"
#      s.port.should == 80
#      
#      r = RemoteService.new( :url=>'https://example.com')
#      s = r.server
#      s.address.should == "example.com"
#      s.port.should == 443
#    end
    
    it "should have default headers" do
      r = RemoteService.new( :url=>'https://example.com')
      h = r.default_http_headers
      h["Content-Type"].should == "application/json"
      h["Accept"].should == "application/json"
    end
    
    it "should have a request url" do
      r = RemoteService.new( :url=>'https://example.com')
      r.request_url("/foo").should == "/foo"
      r.configure  :prefix=>"/xxx"
      r.request_url("/foo").should == "/xxx/foo"
      r.configure  :prefix=>"yyy"
      r.request_url("/foo").should == "/yyy/foo"
      r.configure:prefix=>"zzz/"
      r.request_url("/foo").should == "/zzz/foo"
    end
    
    it "should generate a url_for" do
      r = RemoteService.new( :url=>'https://example.com')
      r.url_for('/aaa/bbb.html').should == 'https://example.com/aaa/bbb.html'
      r = RemoteService.new( :url=>'https://example.com',:prefix=>'foo')
      r.url_for('/aaa/bbb.html').should == 'https://example.com/foo/aaa/bbb.html'
    end
    
    it "should decode a ok response from the server" do
      resp = DummyResponse.new(200, '{"data":true}')
      RemoteService.new.decode_response(resp).should == {"data"=>true}
    end
    
    it "should decode an error response from the server" do
      resp = DummyResponse.new(406, '{"error":"not good"}')
      lambda{RemoteService.new.decode_response(resp)}.should raise_error ServiceError
      resp = DummyResponse.new(500, nil)
      lambda{RemoteService.new.decode_response(resp)}.should raise_error BadRequestError
    end
    
    it "should add an basic auth header if requested" do
      r = RemoteService.new
      r.basic_auth 'foo','mysecret'
      h = r.default_http_headers
      req = Net::HTTP::Get.new("/")
      req.basic_auth 'foo', 'mysecret'
      h["Authorization"].should == req["Authorization"]
      h["Content-Type"].should == "application/json"
      h["Accept"].should == "application/json"
    end
    
    
  end
  
  
  
end