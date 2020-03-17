# the step definitions are executed in an instance of world so
# we can add helper methods for use in the step definitions.

class RestWorld
  # the entry point to the rack application to be tested
  def self.app
    @_app ||= Rack::Builder.parse_file('config.ru').first
  end

  # a dummy request to sent to the server
  def self.request
    @_req ||= Rack::MockRequest.new(app)
  end

  # a class to represent a response from the server
  class Response
    def initialize(resp)
      @resp = resp
      if @resp.header['Content-Type'] == 'application/json'
        begin
          @h = MultiJson.load(@resp.body) || {}
        rescue Exception => e
          puts 'INVALID RESPONSE BODY=>' + @resp.body
          raise
        end
      else
        @h = { 'html' => @resp.body }
      end

      # get_ids_from_hash
    end

    def [](k)
      @h[k]
    end

    def body
      @resp.body
    end

    def data
      @h['data']
    end

    def error
      @h['error']
    end

    def status
      @resp.status.to_i
    end

    def header
      @resp.header || {}
    end

    def content_type
      header['Content-Type']
    end

    def inspect
      @resp.inspect
    end
  end

  # store cookies for each user here
  def cookies
    @_cookies ||= {}
    @_cookies[@_current_user] ||= []
  end

  # store current user information here
  def users
    @_users ||= {}
  end

  # store current user tokens here
  def tokens
    @_tokens ||= {}
  end

  # store general information here
  def store
    @_store ||= {}
  end

  def valid_response
    @_response || raise('no valid response from service')
  end

  def valid_data
    @_response && @_response.data || raise("no valid data returned from service:#{@_response.error}")
  end

  def explain
    puts "request ==> #{@_verb} #{@_request}"
    puts "cookies ==> #{cookies.join('; ')}" if cookies.length > 0
    puts "body ==> #{@_body}" if @_body
    puts "response ==> #{@_response.inspect}"
  end

  def before_parse_path(path); end

  def before_parse_body(json); end

  def parse_path(path)
    path = path.dup

    before_parse_path(path)

    path = path.gsub /\/(@[a-z0-9_]+)/ do |str|
      str = str[2..-1]
      id  = store[str]
      raise ":#{str} has not been stored" unless id
      if id[0] == '/'
        "#{id}"
      else
        "/#{id}"
      end
    end
    # and the query part
    path.gsub /\=(@[a-z0-9_]+)/ do |str|
      str = str[2..-1]
      id  = store[str]
      raise ":#{str} has not been stored" unless id

      "=#{id}"
    end
  end

  def parse_json(json)
    # replace original format
    json = json.gsub /:@([a-z0-9_]+)/ do |str|
      str = str[2..-1]
      id = store[str]
      raise ":#{str} has not been stored" unless id

      if id.is_a?(String)
        ":\"#{id}\""
      else
        ":#{id}"
      end
    end

    # replace alternative format
    json = json.gsub /#\{([a-z0-9_]+)\}/ do |str|
      str = str[2..-2]
      id = store[str]
      raise ":#{str} has not been stored" unless id

      if id.is_a?(String)
        "\"#{id}\""
      else
        "#{id}"
      end
    end
  end

  def parse_body(json)
    json = json.dup
    before_parse_body(json)
    parse_json(json)
  end

  def add_token_to_request
    return if @_request.include?('token=')
    if @_user
      token = @_user.get(:token) || "token12345678-#{@_user.get(:login)}"
      @_request = if @_request.include?('?')
                    @_request + "&token=#{token}"
                  else
                    @_request + "?token=#{token}"
                  end
    end
  end

  def add_token_to_path(path,token)
    return unless token
    if path.include?('?')
      path + "&token=" + token
    else
      path + "?token=" + token
    end
  end

  def rack_request_headers
    env = {}
    env['REMOTE_ADDR'] = '10.0.0.1'
    env['HTTP_COOKIE'] = cookies.join('; ')
    env["HTTP_AUTHORIZATION"] = @_auth if @_auth
    env["HTTP_HOST"] = @_host if @_host
    env
  end

  def request
    RestWorld.request
  end

  def set_host(name)
    @_host = name
  end

  def set_auth_headers(user)
    raise "invalid user name:#{user}" unless u = users[user]
    pw = u.get(:pw)
    raise "iuser name:#{user} has no password!" unless pw
    str = user + ":" + pw
    str = Base64.encode64(str)
    str = "Basic " + str
    #Rack::MockRequest::DEFAULT_ENV["HTTP_AUTHORIZATION"] = str
    @_auth  = str
  end

  # save the response for furthur enquiries and store any cookies.
  def handle_response(raw_response)
    @_auth = nil
    @_response = Response.new(raw_response)
    # add cookies to the cookie jar.
    #unless @_current_user=="guest"
    if cookie = @_response.header["Set-Cookie"]
      parts = cookie.split(';')
      cookies.clear
      cookies << parts[0].strip
    end
    #end
  end

  def parse_user(user)
    user.split(' ')[-1]
  end

  def send_request(verb, username, path, json)
    username = parse_user(username)
    @_verb = verb
    @_body = json && parse_body(json)
    @_request = parse_path(path)
    @_current_user  = username

    if username == 'guest'
      @_user = nil
    else
      @_user = users[username]
      raise "user :#{username} has not been initialized" unless @_user

      pw = @_user.get(:pw)
      add_token_to_request
      set_auth_headers(username)
    end
    case verb
    when 'GET'
      handle_response(request.get(@_request, rack_request_headers))
    when 'POST'
      handle_response(request.post(@_request, rack_request_headers.merge(input: @_body)))
    when 'PUT'
      handle_response(request.put(@_request, rack_request_headers.merge(input: @_body)))
    when 'DELETE'
      handle_response(request.delete(@_request, rack_request_headers.merge(input: @_body)))
    end
  end

  # a hook that is called before creating a user
  def before_user_create(user, hash); end

  # a hook that is called before creating a user
  def after_user_create(user, hash); end
end



World do
  RestWorld.new
end
