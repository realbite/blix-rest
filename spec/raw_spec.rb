require 'spec_helper'


module Blix::Rest

  class RawController < Controller

    get '/myrawdata' do
      send_data "hello", :type=>'application/xyz', :filename=>'message.txt', :status=>204
    end

    get '/rawtext' do
      add_headers 'Content-Type'=>'text/xyz'
      set_status 123
      raise RawResponse, 'xyz'
    end

    get '/rawtext2' do
      raise RawResponse.new('xyz', 123, 'Content-Type'=>'text/xyz')
    end

    get '/rawtext2' do
      send_data "xyz", :type=>'text/xyz', :status=>123
    end

  end


  describe RawResponse do

    before(:all) do
      @app = Server.new
      @srv = Rack::MockRequest.new(@app)
    end

    it "should send basic data" do
      resp = @srv.get('/myrawdata')
      puts resp.inspect
      expect(resp.headers["Content-Type"]).to eq "application/xyz"
      expect(resp.status).to eq 204
    end

    it "should raise raw response" do
      resp = @srv.get('/rawtext')
      puts resp.inspect
      expect(resp.headers["Content-Type"]).to eq "text/xyz"
      expect(resp.status).to eq 123
    end

    it "should raise raw response with status" do
      resp = @srv.get('/rawtext2')
      puts resp.inspect
      expect(resp.headers["Content-Type"]).to eq "text/xyz"
      expect(resp.status).to eq 123
    end

    it "should raise raw response using send_data" do
      resp = @srv.get('/rawtext2')
      puts resp.inspect
      expect(resp.headers["Content-Type"]).to eq "text/xyz"
      expect(resp.status).to eq 123
    end


  end

end
