# frozen_string_literal: true

module Blix::Rest
  # this is the base class for all the format parsers
  class FormatParser

    attr_accessor :__custom_headers

    def set_default_headers(headers)
      # headers[CACHE_CONTROL]= CACHE_NO_STORE
      # headers[PRAGMA]       = NO_CACHE
      # headers[CONTENT_TYPE] = CONTENT_TYPE_JSON
    end

    attr_reader :_format

    attr_writer :_options

    def _options
      @_options || {}
    end

    def _format=(val)
      @_format = val.to_s.downcase
    end

    def self._types
      @_types || []
    end

    def _types
      self.class._types
    end

    # the accept header types that correspont to this parser.
    def self.accept_types(types)
      types = [types].flatten
      @_types = types
    end

    # construct the body of an error messsage.
    def format_error(message)
      message.to_s
    end

    # set the response content / headers / status
    # headers are the default headers if not set
    # status is 200 if not set
    def format_response(value, response)
      response.content = value.to_s
    end

  end

  #-----------------------------------------------------------------------------
  # the default json format parser
  #
  class JsonFormatParser < FormatParser

    accept_types CONTENT_TYPE_JSON

    def set_default_headers(headers)
      headers[CACHE_CONTROL] = CACHE_NO_STORE
      headers[PRAGMA]       = NO_CACHE
      headers[CONTENT_TYPE] = CONTENT_TYPE_JSON
    end

    def format_error(message)
      MultiJson.dump({"error"=>message.to_s}) rescue "{\"error\":\"Internal Formatting Error\"}"
    end

    def format_response(value, response)
      if value.is_a?(RawJsonString)
        response.content = if _options[:nodata]
                             value.to_s
                           else
                             "{\"data\":#{value}}"
                           end
      else
        begin
          response.content = if _options[:nodata]
                               MultiJson.dump(value)
                             else
                               MultiJson.dump('data' => value)
                           end
        rescue Exception => e
          ::Blix::Rest.logger << e.to_s
          response.set(500, format_error('Internal Formatting Error'))
        end
      end
    end

  end

  #-----------------------------------------------------------------------------
  # the default raw format parser
  #
  class RawFormatParser < FormatParser

    # def set_default_headers(headers)
    #   #headers[CACHE_CONTROL]= CACHE_NO_STORE
    #   #headers[PRAGMA]       = NO_CACHE
    # end

    def format_error(message)
      message
    end

    def format_response(value, response)
      response.content = value.to_s
    end

  end

  #-----------------------------------------------------------------------------
  # the default xml format parser
  #
  class XmlFormatParser < FormatParser

    accept_types CONTENT_TYPE_XML

    def set_default_headers(headers)
      headers[CACHE_CONTROL] = CACHE_NO_STORE
      headers[PRAGMA]       = NO_CACHE
      headers[CONTENT_TYPE] = CONTENT_TYPE_XML
    end

    def format_error(message)
      "<error>#{message}</error>"
    end

    def format_response(value, response)
      response.content = value.to_s # FIXME
    end

  end

  #-----------------------------------------------------------------------------
  # the default html format parser
  #
  class HtmlFormatParser < FormatParser

    accept_types CONTENT_TYPE_HTML

    def set_default_headers(headers)
      headers[CACHE_CONTROL] = CACHE_NO_STORE
      headers[PRAGMA]        = NO_CACHE
      headers[CONTENT_TYPE]  = CONTENT_TYPE_HTML
      # headers['X-Frame-Options']        =  'SAMEORIGIN'
      # headers['X-XSS-Protection']       =  '1; mode=block'
      # headers['X-Content-Type-Options'] =  'nosniff'
      # headers['X-Download-Options']     =  'noopen'
      # headers['X-Permitted-Cross-Domain-Policies'] =  'none'
      # headers['Referrer-Policy']        =  'strict-origin-when-cross-origin'
    end

    def format_error(message)
      %(
        <html>
        <head></head>
        <body>
        <p>#{message}</p>
        </body>
        </html>
      )
    end

    def format_response(value, response)
      response.content = value.to_s
    end

  end
end
