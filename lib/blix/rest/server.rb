# frozen_string_literal: true

module Blix::Rest
  class Server

    def initialize(opts = {})
      @_parsers = {}
      @_mime_types = {}

      # register the default parsers and any passed in as options.

      register_parser('html', HtmlFormatParser.new)
      register_parser('json', JsonFormatParser.new)
      register_parser('xml', XmlFormatParser.new)
      register_parser('raw', RawFormatParser.new)
      extract_parsers_from_options(opts)
      @_options = opts
    end

    def _cache
      @_cache ||= {}
    end

    def extract_parsers_from_options(opts)
      opts.each do |k, v|
        next unless k =~ /^(\w*)_parser&/

        format = Regexp.last_match(1)
        parser = v
        register_parser(format, parser)
      end
    end

    def set_custom_headers(format, headers)
      parser = get_parser(format)
      raise "parser not found for custom headers format=>#{format}" unless parser

      parser.__custom_headers = headers
    end

    def get_parser(format)
      @_parsers[format.to_s]
    end

    def get_parser_from_type(type)
      @_mime_types[type.downcase]
    end

    def register_parser(format, parser)
      raise "#{k} must be an object with parent class Blix::Rest::FormatParser" unless parser.is_a?(FormatParser)

      parser._format = format
      @_parsers[format.to_s.downcase] = parser
      parser._types.each { |t| @_mime_types[t.downcase] = parser } # register each of the mime types
    end

    def retrieve_params(env)
      post_params = {}
      body        = ''
      params = env['params'] || {}
      params.merge!(::Rack::Utils.parse_nested_query(env['QUERY_STRING']))

      if env['rack.input']
        post_params = ::Rack::Utils::Multipart.parse_multipart(env)
        unless post_params
          body = env['rack.input'].read
          env['rack.input'].rewind

          if body.empty?
            post_params = {}
          else
            begin
              post_params = case (env['CONTENT_TYPE'])
                            when URL_ENCODED
                              ::Rack::Utils.parse_nested_query(body)
                            when JSON_ENCODED then
                              json = MultiJson.load(body)
                              if json.is_a?(Hash)
                                json
                              else
                                { '_json' => json }
                              end
                            else
                              {}
              end
            rescue StandardError => e
              raise BadRequestError, "Invalid parameters: #{e.class}"
            end
          end
        end
      end
      [params, post_params, body]
    end

    # accept header can have multiple entries. match on regexp
    # can look like this
    # text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8   !!!!!

    def get_format(env)
      case env['HTTP_ACCEPT']
      when JSON_ENCODED then :json
      when HTML_ENCODED then :html
      when XML_ENCODED then :xml
      end
    end

    # attempt to handle mjltiple accept formats here..
    # mime can include '.../*' and '*/*'
    # FIXME
    def get_format_new(env, options)
      accepted = options[:accept] || [:json]
      requested = env['HTTP_ACCEPT'].to_s.split(',')
      requested.each do |request|
        parts = request.split(';')
        mime = parts[0]
        p = get_parser_from_type(mime)
        fmt = p&._format
        return fmt if fmt && (accepted.include?(fmt.to_sym) || accepted.include?(fmt.to_s))
      end
      nil
    end

    # convert the response to the appropriate format
    def format_error(_message, _format)
      parser
    end

    def call(env)
      req = Rack::Request.new(env)

      verb            = env['REQUEST_METHOD']
      path            = req.path

      blk, path_params, options = RequestMapper.match(verb, path)

      blk, path_params, options = RequestMapper.match('ALL', path) unless blk

      default_format = options && options[:default] && options[:default].to_sym
      force_format = options && options[:force] && options[:force].to_sym
      do_cache = options && options[:cache]

      query_format = options && options[:query] && req.GET['format'] && req.GET['format'].to_sym

      format = query_format || path_params[:format] || get_format(env) || default_format || :json

      parser = get_parser(force_format || format)

      return [406, {}, ["Invalid Format: #{format}"]] unless parser

      parser._options = options

      # check for cached response end return with cached response if found.
      #
      if do_cache && _cache[blk.object_id]
        response = _cache[blk.object_id]
        return [response.status, response.headers.merge('X-BLIX-CACHE' => 'CACHED'), [response.content]]
      end

      response = Response.new

      if parser.__custom_headers
        response.headers.merge! parser.__custom_headers
      else
        parser.set_default_headers(response.headers)
      end

      if blk

        begin
          params = env['params']
          value  = blk.call(path_params, params, req, format, response, @_options)
        rescue ServiceError => e
          response.set(e.status, parser.format_error(e.message), e.headers)
        rescue AuthorizationError => e
          response.set(401, parser.format_error(e.to_s), AUTH_HEADER => 'Basic realm="rest"')
        rescue Exception => e
          response.set(500, parser.format_error('internal error'))
          ::Blix::Rest.logger <<  "----------------------------\n#{$!}\n----------------------------"
          ::Blix::Rest.logger <<  "----------------------------\n#{$@}\n----------------------------"
        else # no error
          parser.format_response(value, response)
          # cache response if requested
          _cache[blk.object_id] = response if do_cache
        end

      else
        response.set(404, parser.format_error('Invalid Url'))
      end
      [response.status, response.headers, [response.content]]
    end

  end
end
