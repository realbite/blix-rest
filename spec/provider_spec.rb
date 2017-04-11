require 'spec_helper'

module Realbite::Rest
  
  
  describe Provider do
    
    before(:each) do
      WebFrameService.configure :login=>'foo', :secret=>'mysecret'
      @p = Provider.new(:service=>"myservice")
    end
    
    it "should create the provider" do
      @p.service.should == "myservice"
    end
    
    it "should be a singleton" do
      w1 = Provider.new(:service=>'bar')
      w2 = Provider.new(:service=>'bar')
      w1.object_id.should == w2.object_id
    end
    
    
    
    describe "tokens" do
      
      before (:each) do
        @p.token_cache.clear
      end
      
      it "should validate a good token with the server" do
        Timecop.freeze(Time.parse("2014-11-20 09:00:00 +0100"))
        WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(200, '{"data":{"time":"2014-11-20 08:21:21 +0100","user_id":"12345678"}}'))
        @p.validate_token("12345678").should == "12345678" #Time.parse("2014-11-20 08:21:21 +0100")
      end
      
      it "should not validate a bad token from the server" do
        WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(406,'{"error":"invalid token"}'))
        lambda{@p.validate_token("xxxxxxxx")}.should raise_error ServiceError
      end
      
      it "should cache a valid token for a given time" do
      Timecop.freeze(Time.parse("2014-11-20 08:00:00 +0100"))
      WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(200, '{"data":{"time":"2014-11-20 07:00:00 +0100","user_id":"12345678"}}'))
      @p.validate_token("12345678").should == "12345678"
      
      # token still valid
      Timecop.freeze(Time.parse("2014-11-20 08:30:00 +0100"))
      WebFrameService.instance.server.should_not_receive(:request)
      @p.validate_token("12345678").should == "12345678"
    end
    
    it "should reject an expired token" do
      Timecop.freeze(Time.parse("2014-11-20 08:00:00 +0100"))
      WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(200, '{"data":{"time":"2014-11-20 07:00:00 +0100","user_id":"12345678"}}'))
      @p.validate_token("12345678").should == "12345678"
      
      # expired token
      Timecop.freeze(Time.parse("2014-11-21 07:00:00 +0100"))
      WebFrameService.instance.server.should_not_receive(:request)
      lambda{@p.validate_token("12345678")}.should raise_error ServiceError
    end
    
    it "should reject an already expired token" do
      #already expired token
      Timecop.freeze(Time.parse("2014-11-21 09:00:00 +0100"))
      WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(200, '{"data":{"time":"2014-11-20 07:00:00 +0100","user_id":"12345678"}}'))
      WebFrameService.instance.server.should_receive(:request)
      lambda{@p.validate_token("22222222")}.should raise_error ServiceError
    end
    
    it "should retrieve the user_wid of ther service" do
      WebFrameService.instance.server.stub(:request).and_return(DummyResponse.new(200,'{"data":{"user_wid":"12345"}}'))
      WebFrameService.user_wid.should == "12345"
    end
    
  end
end



end