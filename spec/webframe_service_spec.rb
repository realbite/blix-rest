require 'spec_helper'

module Realbite::Rest
  
  
  describe WebFrameService do
    
    it "should be a singleton" do
      w1 = WebFrameService.new(:login=>'foo',:secret=>'bar')
      w2 = WebFrameService.new(:login=>'foo',:secret=>'bar')
      w1.object_id.should == w2.object_id
    end
    
    it "should have a default url" do
      WebFrameService.new(:login=>'foo',:secret=>'bar')
      WebFrameService.new.url.should == 'http://localhost:9292'
      WebFrameService.new(:url=>'http://example.com',:login=>'foo',:secret=>'bar').url.should == 'http://example.com'
    end
    
    it "should have auth headers" do
      WebFrameService.new(:url=>'http://example.com',:login=>'foo',:secret=>'bar')
      WebFrameService.instance.default_http_headers.should include 'Authorization'
    end
    
  end


end