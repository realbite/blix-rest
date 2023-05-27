require 'spec_helper'

module Blix::Rest

  describe ServiceError do

    it "should return message as string" do
      e = ServiceError.new("foo",123,"location"=>"/newpath")
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

  describe "handle mime types" do
    it "should register the type" do
        s = Server.new
        parser = s.get_parser("json")
        parser._format.should == "json"
        parser._types.should == [CONTENT_TYPE_JSON]
    end

    it "should find a parser for a mime type" do
        s = Server.new
        parser = s.get_parser_from_type(CONTENT_TYPE_JSON)
        parser._format.should == "json"
        parser._types.should == [CONTENT_TYPE_JSON]
    end

  end



  describe HtmlFormatParser do

    it "should parse a redirect message" do
      e = ServiceError.new(nil,302,"location"=>"/newpath")
      message = HtmlFormatParser.new.format_error(e.message)
      message.should include("<p></p>")
    end
  end

end
