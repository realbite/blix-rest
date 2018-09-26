require 'spec_helper'



module Blix::Rest
  
  class TestController < Controller
    
    attr_accessor :name, :title
    
    def initialize
      
    end
    
    def logmessage(msg)
      logger.info msg
    end
    
  end
  
  describe "Controller Verbs" do
    
    it "should generate error responses" do
      
      t = TestController.new
      expect{ t.send(:send_error,"foo",123)}.to raise_error ServiceError,"foo"
      expect{ t.send(:auth_error,"bar")}.to raise_error AuthorizationError,"bar"
    end
    
  end
end
