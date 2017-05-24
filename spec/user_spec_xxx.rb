require 'spec_helper'

module Realbite::WebFrame
  
  describe User do
    
    before(:each) do
      Database.drop_table("user") rescue nil
    end
    
    it "should create a new user" do
      User.count.should == 0
      u = User.new(:name=>"foo")
      u.save
      User.count.should == 1
      u = User.new(:name=>"bar")
      u.save
      User.count.should == 2
      puts User.all.inspect
    end
    
    it "should create an id" do
      u = User.new(:name=>"foo")
      u.id.should == nil
      u.save
      u.id.should_not == nil
      User.find(u.id).should_not == nil
      puts  User.find(u.id).inspect
    end
    
    it "should find user by name" do
      u1 = User.new(:name=>"foo")
      u1.save
      u2 = User.new(:name=>"bar")
      u2.save
      User.find_by(:name,"xxx").should == []
      f = User.find_by(:name,"bar")[0]
      f.id.should == u2.id
    end
    
    it "should update a user" do
      u = User.new(:name=>"foo", :age=>12)
      u.save
      id = u.id
      u = User.find(id)
      u.set(:name,"bar")
      u = User.find(id)
      u.get(:name).should == "foo" # not saved
      u.set(:name,"bar")
      u.save
      u = User.find(id)
      u.get(:name).should == "bar"
    end
    
    it "should delete a user" do
      u = User.new(:name=>"foo")
      u.save
      User.count.should == 1
      u = User.new(:name=>"bar")
      u.save
      User.count.should == 2
      id = u.id
      u.destroy
      User.count.should == 1
      User.find(id).should == nil
    end
    
  end
  
  
end