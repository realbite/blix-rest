require 'spec_helper'


module Realbite::WebFrame
  
  describe VersionController do
    
    include RequestHelpers
    
    it 'should return the version' do
      r = server_get "/info"
      r.status.should == 200
      r.data["version"].should == VERSION
      r.content_type.should == TYPE_JSON
      r.error.should == nil
    end
  end
end