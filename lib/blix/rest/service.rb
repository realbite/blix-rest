module Blix::Rest
  
  
  # class to connect as a client to a service registered with webframe.
  #. This class will take care of authentication
  #
  class Service < RemoteService
    
    attr_reader :name
    attr_reader :token
    
    # create a new service object with the name of the service
    def initialize(name,params={})
      @name = name
      super(params)
    end
    
    # auto configure the service by obtaining the service info from the 
    # webframe.
    
    def auto_configure
      resp = webframe.get "/myservices/#{@name}"
      service_url = resp["data"]["url"]
      service_prefix = resp["data"]["prefix"]
      raise "auto configure of service #{@name} failed" unless service_url
      configure :url=>service_url, :prefix=>prefix
    end
    
    def webframe
      WebFrameService.instance
    end
    
    
    # the user must have a token in order to use the service. if there is no token or 
    # the token is expired then the user will have to request a new token from the
    # webframe service.
    def token
      @token
    end
    
    # get a new token from the webframe
    def refresh_token
      resp = webframe.post "/myservices/#{@name}/token"
      @token = resp["data"]["token"]
    end
    
    # overwrite the request_url method to add a token to each request.
    def request_url(path)
      # if we do not have a token then request one from the webframe
      refresh_token unless @token
      if path.include?('?')
        link = '&token='
      else
        link = '?token='
      end
      @prefix.to_s + path + link + @token
    end
    
    # if the request fails because of an expired token then request a new token and 
    # try the request again.
    def request(req)
      begin
        super
      rescue WebFrameError=>e
        if (e.message == EXPIRED_TOKEN_MESSAGE) || (e.message == INVALID_TOKEN_MESSAGE)
          @token = nil
          refresh_token
          query_hash = req.query_hash
          query_hash["token"] = @token
          req.replace_query(query_hash) # replace token in request with new token
          #headers = default_http_headers
          #request = req.class.new(req.verb,req.url,path,headers)       
          #request.body = req.body if req.body
          super(req)     # and rerequest
        else
          raise
        end
      end
    end
    
  end
end