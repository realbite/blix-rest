require 'thread'

module Blix::Rest
  
  # this class provides a connection to the webframe server. The connection uses basic auth 
  # to supply the login and password.
  #
  class WebFrameService < RemoteService
    
    DEFAULT_WEBFRAME_URL = 'http://localhost:9292'
    
    class << self
      
      alias :old_new :new
      
      def new(params=nil)
        instance
        instance.configure(params) if params
        instance
      end
      
      def user_wid
        @_wid ||= begin
          d = get('/info')["data"]
          d && d["user_wid"]
        end
      end
      
      def instance
        @_instance ||= old_new
      end
      
      def configure(*a)
        instance.configure(*a)
      end
      
      def get(*a)
        instance.get(*a)
      end
      
      def post(*a)
        instance.post(*a)
      end
      
      def put(*a)
        instance.put(*a)
      end
      
      def delete(*a)
        instance.delete(*a)
      end
      
      def url_for(*a)
        instance.url_for(*a)
      end
      
      def validate_token(token)
        get("/login/token/#{token}/validate")["data"]
      end
    end
    
    
    # configure the connection 
    def configure(params)
      params = {:url=>DEFAULT_WEBFRAME_URL}.merge(params)
      super(params)
      
      login       = params[:login]
      secret      = params[:secret]
      
      if login || params[:authenticated]
        raise "login missing" unless login
        raise "secret missing" unless secret
        
        basic_auth(login,secret)
      end
      @logger = params[:logger] || Logger.new(STDOUT)
      @logger.info "WebFrameService configured url:#{url}"
      self
    end
    
  end
  
end