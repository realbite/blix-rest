module Blix::Rest
  
  # base class for controllers. within your block handling a particular route you
  # have access to a number of methods
  #
  # env          : the request environment hash
  # body         : the request body as a string
  # body_hash    : the request body as a hash constructed from json
  # query_params : a hash of parameters as passed in the url as parameters
  # path_params  : a hash of parameters constructed from variable parts of the path
  # params       : all the params combined
  # user         : the user making this request ( or nil if 
  
  
  class ProviderController < Controller
    
    
    def authorize_token(token)
      @user_wid = Provider.instance.validate_token(token)
    end
    
    def authorize_session(token)
      info = Provider.instance.validate_session(token)
      @user_wid = info[0]
      @session  = info[1]
    end
    
    def user_wid
      @user_wid
    end
    
    def session
      @session
    end
    
    # 
    def user_is_provider?
       WebFrameService.user_wid == user_wid
    end
    
    # check that that user is authorized to use this service. If the user is authorized then cache the 
    # result for a given time. The user provides a token 
    def before(opts)
      if opts[:session_only]
       session = query_params["session_id"]
       authorize_session(session)
      else
        token = query_params["token"]
        authorize_token(token)
      end
    end
    
  end
  
end