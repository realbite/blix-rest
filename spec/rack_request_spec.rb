require 'spec_helper'
require 'test_controllers'

CONTENT_TYPE      = 'Content-Type'
CONTENT_TYPE_JSON = 'application/json'
CONTENT_TYPE_HTML = 'text/html'
CONTENT_TYPE_XML  = 'application/xml'
ACCEPT = "HTTP_ACCEPT"

module Blix::Rest

  describe "basic request" do

    before(:all) do
      @app = Server.new
      @srv = Rack::MockRequest.new(@app)
    end

    it "should return a response" do
      resp = @srv.get("/xxx", {})
      resp.status.should == 404
    end

    it "should return status 200 response" do
      resp = @srv.get("/status_200", {})
      resp.status.should == 200
    end

    it "should return error response" do
      resp = @srv.get("/error_440", {})
      resp.status.should == 440
    end

    it "should extract query parameters" do
      resp = @srv.get("/testecho?foo=bar&xxx=yyy", {})
      h  = MultiJson.load(resp.body)
      h["data"]["query_params"].should == {"foo"=>"bar","xxx"=>"yyy"}
      h["data"]["path_params"].should == {}
      h["data"]["body_hash"].should == {}
    end

    it "should extract body parameters" do
      resp = @srv.post("/testecho?foo=bar&xxx=yyy", :input=>'{"aaa":"bbb","qty":123.45}')
      h  = MultiJson.load(resp.body)
      h["data"]["query_params"].should == {"foo"=>"bar","xxx"=>"yyy"}
      h["data"]["path_params"].should == {}
      h["data"]["body_hash"].should == {"aaa"=>"bbb","qty"=>123.45 }
    end

    #it "should handle invalid json hash" do
    #  resp = @srv.get("/invalid_hash", {})
    #  puts resp.inspect
    #  resp.status.should == 500
    #end

    it "should handle invalid format" do
      resp = @srv.get("/status_200.jsonx", {})
      resp.status.should == 406
    end

    it "should set a special status" do
      resp = @srv.get("/teststatus", {})
      resp.status.should == 401
      resp.body.should == '{"data":"newstatus"}'
    end

    it "should set a special headers" do
      resp = @srv.get("/testheaders", {})
      resp.status.should == 200
      resp.body.should == '{"data":"newheaders"}'
    end

    describe "request format" do

      after(:each) do
        Rack::MockRequest::DEFAULT_ENV = {}
        #Rack::MockRequest::DEFAULT_ENV.delete(ACCEPT)
      end

       it "should default to json" do
         resp = @srv.post("/testecho")
         resp.headers[CONTENT_TYPE].should == CONTENT_TYPE_JSON
       end

       it "should look at json extension" do
         resp = @srv.post("/testecho.json")
         resp.headers[CONTENT_TYPE].should == CONTENT_TYPE_JSON
       end

       it "should look at json accept header" do
         Rack::MockRequest::DEFAULT_ENV[ACCEPT] = CONTENT_TYPE_JSON
         resp = @srv.post("/testecho")
         resp.headers[CONTENT_TYPE].should == CONTENT_TYPE_JSON
       end

        it "should look at xml extension" do
         resp = @srv.post("/testecho.xml")
         resp.headers[CONTENT_TYPE].should == CONTENT_TYPE_XML
       end

       it "should look at xml accept header" do
         Rack::MockRequest::DEFAULT_ENV[ACCEPT] = CONTENT_TYPE_XML
         resp = @srv.post("/testecho")
         resp.headers[CONTENT_TYPE].should == CONTENT_TYPE_XML
       end

      it "should look at html extension" do
         resp = @srv.post("/testecho.html")
         resp.headers[CONTENT_TYPE].should == CONTENT_TYPE_HTML
       end

       it "should look at html accept header" do
         Rack::MockRequest::DEFAULT_ENV[ACCEPT] = CONTENT_TYPE_HTML
         resp = @srv.post("/testecho")
         resp.headers[CONTENT_TYPE].should == CONTENT_TYPE_HTML
       end

       it "should accept the geojson format when registered" do
         resp = @srv.get("/testgeojson.html")
         resp.status.should == 406

         resp = @srv.get("/testgeojson.json")
         resp.status.should == 406

         resp = @srv.get("/testgeojson.geojson")
         resp.status.should == 406
         @app.register_parser(:geojson,GeoFormatParser.new)
         resp = @srv.get("/testgeojson.geojson")
         resp.status.should == 200
         resp.body.should == '{"geodata":"data"}'

         resp = @srv.get("/testgeojson.json")
         resp.status.should == 406
       end
    end

  end

end
