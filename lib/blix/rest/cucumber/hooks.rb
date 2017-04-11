Before do
  @_app = Realbite::Rest::Server.new
  @_srv = Rack::MockRequest.new(@_app)
  Realbite::Rest::RequestMapper.set_path_root(nil)

end