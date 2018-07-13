# the step definitions are executed in an instance of world so
# we can add helper methods for use in the step definitions.



class RestWorld
  
  # a class to represent a response from the server
  class Response
    
    def initialize(resp)
      @resp = resp
      begin
        @h  = MultiJson.load(@resp.body) || {}
      rescue Exception=>e
        puts "INVALID RESPONSE BODY=>" + @resp.body
        raise
      end
      #get_ids_from_hash
    end
    
    def [](k)
      @h[k]
    end
    
    def data
      @h["data"]
    end
    
    def error
      @h["error"]
    end
    
    def status
      @resp.status.to_i
    end
    
    def header
      @resp.header || {}
    end
    
    def content_type
      header["Content-Type"]
    end
    
    def inspect
      @resp.inspect
    end
    
    #    
    #    
    #    def get_ids_from_hash
    #      d = data
    #      if d.kind_of? Array
    #        d = d[0]
    #      end
    #      if d && d.kind_of?(Hash)
    #        type = d["_type"] + "_"
    #        d.each do |k,v|
    #          if (k[-3,3]=="_id") || (k=="id")
    #            Response.ids[type + k] = v
    #          end
    #        end
    #      end
    #    end
    
    
  end
  
  def users
    @_users ||= {}
  end
  
  def tokens
    @_tokens ||= {}
  end
  
  def store
    @_store ||= {}
  end
  
  def valid_response
    @_response || raise("no valid response from service")
  end
  
  def valid_data
    @_response && @_response.data ||  raise("no valid data returned from service:#{@_response.error}")
  end
  
  def before_parse_path(path)
  end
  
  def before_parse_body(json)
  end
  
  def parse_path(path)
  
    path = path.dup
  
    before_parse_path(path)
    
    path = path.gsub /\/(@[a-z0-9_]+)/ do |str|
      str = str[2..-1]
      id  = store[str]
      raise ":#{str} has not been stored" unless id
      "/#{id}"
    end
    # and the query part
    path.gsub /\=(@[a-z0-9_]+)/ do |str|
      str = str[2..-1]
      id  = store[str]
      raise ":#{str} has not been stored" unless id
      "=#{id}"
    end
  end
  
  ############################################## ALTERNATIVE FORM
  def parse_params_XXXXXXX(json)
    # replace any ids in the string
    json.gsub( /[:|\[|,|\W]@([a-z0-9_\/\.]+)/) do |str|
      #puts "SSSSSSSSSSSSTR=#{str}"
      char = str[0,1]
      str = str[2..-1]
      if str=="password"
        id = @current_user && @current_user.name + "@12345678"
      elsif str[0,5] == "image"
        data = File.read("resources/images" + str[5..-1])
        id = data && Base64.strict_encode64(data)
        #id = "12345"
      else
        id  = store[str]
      end
      raise ":#{str} has not been stored" unless id
      "#{char}\"#{id}\""
    end
  end
  
  def parse_body(json)
  
    json = json.dup
    
    before_parse_body(json)
    json.gsub /:@([a-z0-9_]+)/ do |str|
      str = str[2..-1]
      id  = store[str]
      raise ":#{str} has not been stored" unless id
      ":\"#{id}\""
    end
  end
  
  
  def add_token_to_request
    if @_user
      if @_request.include?('?')
        @_request = @_request + "&token=token12345678-#{@_user.get(:login)}"
      else
        @_request = @_request + "?token=token12345678-#{@_user.get(:login)}"
      end
    end
  end
  
  def rack_request_headers
    env = {}
    env["REMOTE_ADDR"] = "10.0.0.1"
    env
  end
  
  
  def send_request(verb,username,path,json)
    @_verb = verb
    @_body = json && parse_body(json)
    @_request = parse_path(path)
    
    if username == "guest"
      @_user = nil
    else
      @_user = users[username]
      raise "user :#{username} has not been initialized" unless @_user
      pw = @_user.get(:pw)
      add_token_to_request
    end
    case verb 
    when 'GET'
      @_response = Response.new(@_srv.get(@_request, rack_request_headers))
    when 'POST'
      @_response = Response.new(@_srv.post(@_request, rack_request_headers.merge(:input=>@_body))) 
    when 'PUT'
      @_response = Response.new(@_srv.put(@_request, rack_request_headers.merge(:input=>@_body))) 
    when 'DELETE'
      @_response = Response.new(@_srv.delete(@_request, rack_request_headers.merge(:input=>@_body))) 
    end
  end
  
  # a hook that is called before creating a user
  def before_user_create(user,hash)
  end
end

World do
  RestWorld.new
end


