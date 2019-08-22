Before do
  #@_app = Blix::Rest::Server.new
  #@_srv = Rack::MockRequest.new(@_app)
  Blix::Rest::RequestMapper.set_path_root(nil)
end
