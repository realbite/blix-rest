require 'spec_helper'
require 'test_controllers'

CONTENT_TYPE      = 'Content-Type'
CONTENT_TYPE_JSON = 'application/json'
CONTENT_TYPE_HTML = 'text/html'
CONTENT_TYPE_XML  = 'application/xml'
ACCEPT = "HTTP_ACCEPT"

module Blix::Rest

  describe Server do

    before(:all) do
      @app = Server.new
      @srv = Rack::MockRequest.new(@app)
      @app.set_custom_headers(:html, nil)
    end

    it "should add headers to 200 response" do
      resp = @srv.get('/200header')
      expect(resp.header["XXX"]).to eq "200"
    end

    it "should add headers to 302 response" do
      resp = @srv.get('/302header')
      expect(resp.header["XXX"]).to eq "302"
    end

    it "should add headers to error response" do
      resp = @srv.get('/406header')
      expect(resp.header["XXX"]).to eq "406"
    end

    it "should add custom headers" do

      @app.set_custom_headers(:html, 'YYY'=>'hello')
      resp = @srv.get('/200header.html')
      expect(resp.header.length).to eq 3  # adds content length
      expect(resp.header["XXX"]).to eq "200"
      expect(resp.header["YYY"]).to eq "hello"
    end


  end

end
