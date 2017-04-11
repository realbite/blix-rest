require 'spec_helper'

module Realbite::WebFrame
  
  describe UserManager do
    
    before(:each) do
      Database.drop_table("user") rescue nil
      @m = UserManager.new
      @pw = "12345"
      @hash = @m.encode_password(@pw)
    end
    
    it "should encode a password" do
      @pw.should_not == @hash
      @hash.should == @m.encode_password(@pw)
    end
    
    it "should authorise a user" do
      u = User.new(:name=>"foo", :login=>"admin", :password_hash=>@hash)
      u.save
      User.count.should == 1
      lambda{@m.authorize_user("aaa","bbb")}.should raise_error AuthorizationError
      lambda{@m.authorize_user(nil,nil)}.should raise_error AuthorizationError
      lambda{@m.authorize_user("admin",nil)}.should raise_error AuthorizationError
      lambda{@m.authorize_user(nil,"12345")}.should raise_error AuthorizationError
      lambda{@m.authorize_user("admin","12345")}.should_not raise_error
    end
    
    it "encode password has to be fast" do
      u = User.new(:name=>"foo", :login=>"admin", :password_hash=>@hash.to_s)
      u.save
      count = 10
      t = Time.now
      count.times do
        @m.authorize_user("admin","12345")
      end
      dur = (Time.now - t) * 1000 / count   # in ms
      dur.should < 2  # allow 5ms per request
    end
    
    
    
  end
  
  
end