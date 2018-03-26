module Blix::Rest
  
  class Server 

    def initialize(opts={})
      @_parsers={}
      extract_parsers_from_options(opts)
      @_parsers["html"]  ||= HtmlFormatParser.new
      @_parsers["json"]  ||= JsonFormatParser.new
      @_parsers["xml"]   ||= XmlFormatParser.new
      @_options = opts
    end
    
    def extract_parsers_from_options(opts)
      opts.each do |k,v|
        if k=~/^(\w*)_parser&/
          format = $1
          parser = v 
          register_parser(format,parser)
        end
      end
    end
    
    def get_parser(format)
      @_parsers[format.to_s]
    end
    
    def register_parser(format,parser)
      raise "#{k} must be an object with parent class Blix::Rest::FormatParser" unless parser.kind_of?(FormatParser)
      @_parsers[format.to_s.downcase] = parser
    end
    
    def retrieve_params(env)
      post_params = {}
      body        = ""
      params = env['params'] || {}
      params.merge!(::Rack::Utils.parse_nested_query(env['QUERY_STRING']))
      
      if env['rack.input']
        post_params = ::Rack::Utils::Multipart.parse_multipart(env)
        unless post_params
          body = env['rack.input'].read
          env['rack.input'].rewind
          
          unless body.empty?
            begin
              post_params = case(env['CONTENT_TYPE'])
              when URL_ENCODED then
                ::Rack::Utils.parse_nested_query(body)
              when JSON_ENCODED  then
                json = MultiJson.load(body)
                if json.is_a?(Hash)
                  json
                else
                  {'_json' => json}
                end
              else
                {}
              end
            rescue StandardError => e
              raise BadRequestError, "Invalid parameters: #{e.class.to_s}"
            end
          else
            post_params = {}
          end
        end
      end
      [params,post_params,body]
    end
    
    def get_format(env)
      case env['HTTP_ACCEPT']
      when JSON_ENCODED then :json
      when HTML_ENCODED then :html
      when XML_ENCODED then :xml
      else
        nil
      end
    end
    
    # convert the response to the appropriate format
    def format_error(message, format)
      parser
    end
    
    
    def call(env)
      
      req = Rack::Request.new(env)
      
      verb            = env["REQUEST_METHOD"]
      path            = req.path #env["REQUEST_PATH"] || "/"
      
      blk,path_params = RequestMapper.match(verb,path)
      
      format = path_params[:format] || get_format(env) || :json
      parser = get_parser(format)
      
      unless parser
        return [406,{},["Invalid Format: #{format}"]]
      end
      
      response = Response.new
      
      parser.set_default_headers(response.headers)
      
      if blk
        
        begin
          params = env['params']
          value  = blk.call(path_params,params,req,format,response,@_options)
        rescue ServiceError=>e
          response.set(e.status,parser.format_error(e.message),e.headers)
        rescue AuthorizationError=>e
          response.set(401,parser.format_error(e.to_s),{AUTH_HEADER=>'Basic realm="rest"'})
        rescue Exception=>e
          response.set(500,parser.format_error("internal error"))
          puts $!  # FIXME should go to logger
          puts $@  # FIXME should go to logger
        else # no error
          parser.format_response(value,response)
        end
        
      else
        response.set(406,parser.format_error("Invalid Url"))
      end
      [response.status,response.headers, [response.content]]
    end
  end
end