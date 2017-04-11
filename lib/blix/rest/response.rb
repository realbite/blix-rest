# pass a response object to the controller to set
# header status and content.

module Blix::Rest
  
  
  class Response
    
    attr_accessor :status
    attr_reader   :headers
    attr_accessor :content
    
    def initialize
      @status  = 200
      @headers  = {}
      @content = nil
    end
    
    def set(status,content=nil,headers=nil)
      @status = status if status
      @content = content if content
      @headers.merge!(headers) if headers
    end
    
  end
end