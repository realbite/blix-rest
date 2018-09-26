require 'thread'

module Blix::Rest
  
  # 
  # 
  #
  
  class Provider
    
    attr_reader :service
    attr_reader :parameters
    
    class << self
      
      alias :old_new :new
      
      def new(params=nil)
        instance
        instance.configure(params) if params
        instance
      end
      
      def instance
        @_instance ||= old_new
      end
      
      def configure(*a)
        instance.configure(*a)
      end
    end
    
    # configure the connection 
    def configure(params)
      @parameters           = params
      @service              = params[:service]
      @_token_cache         = {}
      @token_cache_time     = Time.now
      @token_expiry_seconds = params[:token_expiry_seconds] || 60 * 60 * 24
      self
    end
    
    # FIXME .. we will need to clear out old tokens from the cache periodically.
    def token_cache
      @token_mutex ||= Mutex.new  # is this neccessary ?? does it matter if another thread
      # clears the cache ??
      @token_mutex.synchronize do
        if (Time.now - @token_cache_time) > @token_expiry_seconds
          @token_cache_time = Time.now
          @_token_cache = {}
        end
        @_token_cache
      end
    end
    
    # make a call to the webframe api to authorize a token. 
    # FIXME delete any other tokens for this user from the cache otherwise
    # a user could use many tokens simultaneously until the cache expires.
    def validate_token(token)
      
      raise ServiceError.new("token missing",401) unless token
      raise "service name not configured" unless service
      # first check if the token is in the cache
      token_info = token_cache[token]
      
      if token_info
        token_time = token_info[0]
        user_id    = token_info[1]
        if (Time.now - token_time)  < @token_expiry_seconds
          return user_id
        else
          # should we delete the token from the cache here ??
          raise ServiceError.new(EXPIRED_TOKEN_MESSAGE,401)
        end
      end
      
      # token not found ..
      path = "/services/#{service}/validate/#{token}"
      
      begin
        r = WebFrameService.get path
      rescue WebFrameError
        raise ServiceError.new(INVALID_TOKEN_MESSAGE,403)
      end
      
      time_string = r["data"]["time"]
      user_id     = r["data"]["user_id"]
      
      token_time = time_string && Time.parse( time_string )
      
      if token_time
        
        if (Time.now - token_time)  < @token_expiry_seconds
          token_cache[token] = [token_time,user_id]
          return user_id
        else
          token_cache[token] = [token_time,user_id] # FIXME .. should we be keeping expired tokens in the cache ??
          raise ServiceError.new(EXPIRED_TOKEN_MESSAGE,401)
        end
      end
    end
    
    # check if this is a valid session token.. if so then store in the cache
    def validate_session(token)
      raise ServiceError.new("token missing",401) unless token
      raise "service name not configured" unless service
      # first check if the token is in the cache
      token_info = token_cache[token]
      
      if token_info
        token_time = token_info[0]
        user_id    = token_info[1]
        if (Time.now - token_time)  < @token_expiry_seconds
          return user_id
        else
          # should we delete the token from the cache here ??
          raise ServiceError.new(EXPIRED_TOKEN_MESSAGE,401)
        end
      end
      
      # token not found ..
      "/sessions/:session_token/services/:service_name/validate"
      path = "/sessions/#{token}/validate/#{service}"
      
      begin
        r = WebFrameService.get path
      rescue WebFrameError
        raise ServiceError.new(INVALID_TOKEN_MESSAGE,403)
      end
      
      time_string = r["data"]["time"]
      user_id     = r["data"]["user_id"]
      
      token_time = time_string && Time.parse( time_string )
      
      if token_time
        if (Time.now - token_time)  < @token_expiry_seconds
          token_cache[token] = [token_time,user_id]
          return user_id
        else
          token_cache[token] = [token_time,user_id] # FIXME .. should we be keeping expired tokens in the cache ??
          raise ServiceError.new(EXPIRED_TOKEN_MESSAGE,401)
        end
      end
      end
      
  end
  
end