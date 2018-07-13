
module Blix::Rest
  
  # this is the base class for all the format parsers
  class FormatParser
    
    def set_default_headers(headers)
      headers[CACHE_CONTROL]= CACHE_NO_STORE 
      headers[PRAGMA]       = NO_CACHE 
      headers[CONTENT_TYPE] = CONTENT_TYPE_JSON
    end
    
    # construct the body of an error messsage.
    def format_error(message)
      message.to_s
    end
    
    # set the response content / headers / status
    # headers are the default headers if not set
    # status is 200 if not set
    def format_response(value,response)
      response.content = value.to_s
    end
    
  end
  
  #-----------------------------------------------------------------------------
  # the default json format parser
  #
  class JsonFormatParser < FormatParser
    
    def set_default_headers(headers)
      headers[CACHE_CONTROL]= CACHE_NO_STORE 
      headers[PRAGMA]       = NO_CACHE 
      headers[CONTENT_TYPE] = CONTENT_TYPE_JSON
    end
    
    
    def format_error(message)
      "{\"error\":\"#{message}\"}"
    end
    
    def format_response(value,response)
      begin
        response.content = MultiJson.dump({"data"=>value})
      rescue Exception=>e
        response.set(500,format_error("Internal Formatting Error"))
      end
    end
  end
  
  #-----------------------------------------------------------------------------
  # the default raw format parser
  #
  class RawFormatParser < FormatParser
    
    def set_default_headers(headers)
      #headers[CACHE_CONTROL]= CACHE_NO_STORE 
      #headers[PRAGMA]       = NO_CACHE 
    end
    
    def format_error(message)
      message
    end
    
    def format_response(value,response)
      response.content = value.to_s 
    end
  end
  
  #-----------------------------------------------------------------------------
  # the default xml format parser
  #
  class XmlFormatParser < FormatParser
    
    def set_default_headers(headers)
      headers[CACHE_CONTROL]= CACHE_NO_STORE 
      headers[PRAGMA]       = NO_CACHE 
      headers[CONTENT_TYPE] = CONTENT_TYPE_XML
    end
    
    def format_error(message)
      "<error>#{message}</error>"
    end
    
    def format_response(value,response)
      response.content = value.to_s # FIXME
    end
  end
  
  #-----------------------------------------------------------------------------
  # the default html format parser
  #
  class HtmlFormatParser < FormatParser
    
    def set_default_headers(headers)
      headers[CACHE_CONTROL]= CACHE_NO_STORE 
      headers[PRAGMA]       = NO_CACHE 
      headers[CONTENT_TYPE] = CONTENT_TYPE_HTML
    end
    
    def format_error(message)
      %Q~
        <html>
        <head></head>
        <body>
        <p>#{message}</p>
        </body>
        </html>
      ~
    end
    
    def format_response(value,response)
      response.content = value.to_s
    end
  end
end