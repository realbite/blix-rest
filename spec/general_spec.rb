require 'spec_helper'

module Blix::Rest

  describe StringHash do

    it "should return value or default" do
      e = StringHash.new
      e[:a] = 1
      e['b'] = 2
      e[:a].should ==1
      e['a'].should == 1
      e[:b].should == 2
      e['b'].should == 2
      e[:c].should == nil
      e['c'].should == nil
      e.get(:a).should == 1
      e.get('a').should == 1
      e.get(:c).should == nil
      e.get('c').should == nil
      e.get(:c,5).should == 5
      e.get('c',5).should == 5
    end
  end




end
