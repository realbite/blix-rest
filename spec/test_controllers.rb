class GeoFormatParser < Blix::Rest::FormatParser

    def set_default_headers(headers)

    end

    def format_error(message)
      MultiJson.dump({"geoerror"=>message})
    end

    def format_response(value,response)
      response.content = MultiJson.dump({"geodata"=>value})
    end
  end


module Blix

  class TestController < Blix::Rest::Controller

    get "/status_200" do
      h = {"test"=>"hello", "version"=>Blix::Rest::VERSION}
      h
    end

    get "/error_440" do
      raise Blix::Rest::ServiceError.new( "test error",440)
    end

    get "/invalid_hash" do
      {"aaa"=>lambda{raise}}
    end

    get "/testecho", :accept=>[:json,:html, :xml] do
      {"query_params"=>query_params,"path_params"=>path_params,"body_hash"=>body_hash}
    end

    post "/testecho" , :accept=>[:json,:html, :xml] do
      {"query_params"=>query_params,"path_params"=>path_params,"body_hash"=>body_hash}
    end

    get  "/teststatus" do
      set_status 401
      "newstatus"
    end

    get "/testheaders" do
      add_headers "MYHEADER"=>"BOB", "EXTRA-HEADER"=>"1234"
      "newheaders"
    end

    get  "/testgeojson", :accept=>[:geojson] do
      "data"
    end

    get "/200header", :accept=>[:json,:html] do
      add_headers "XXX"=>"200"
      "ok"
    end

    get "/302header" do
      add_headers "XXX"=>"302"
      redirect "/otherpath"
    end

    get "/406header" do
      add_headers "XXX"=>"406"
      send_error("oops")
    end

  end
end
