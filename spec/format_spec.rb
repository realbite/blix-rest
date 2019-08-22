require 'spec_helper'

module Blix::Rest

  describe ServiceError do

    it "should return message as string" do
      e = ServiceError.new("foo",123,"Location"=>"/newpath")
      e.to_s.should == "foo"
      "#{e}".should == "foo"
      e.message.should == "foo"
    end

    it "should handle nil message" do
      e = ServiceError.new(nil)
      e.to_s.should == ""
      "#{e}".should == ""
      e.message.should == ""
    end
  end



  describe HtmlFormatParser do

    it "should parse a redirect message" do
      e = ServiceError.new(nil,302,"Location"=>"/newpath")
      message = HtmlFormatParser.new.format_error(e.message)
      message.should include("<p></p>")
    end
  end

end
