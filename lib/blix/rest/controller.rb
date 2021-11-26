# frozen_string_literal: true

require 'base64'
require 'erb'
require 'securerandom'
require 'digest'

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
  # format       : the format the response should be in :json or :html
  # session      : the rack session if middleware has been used
  #
  #  to accept requests other thatn json then set :accept=>[:json,:html] as options in the route
  #    eg  post '/myform' :accept=>[:html]              # this will only accept html requests.

  Context = Struct.new(
    :path_params,
    :params,
    :req,
    :format,
    :server_options,
    :response
  )

  class Controller


    #--------------------------------------------------------------------------------------------------------
    # convenience methods
    #--------------------------------------------------------------------------------------------------------
    def env
      @_env
    end

    # options that were passed to the server at create time.
    def server_options
      @_server_options
    end

    def logger
      Blix::Rest.logger
    end

    def rack_env
      ENV['RACK_ENV']
    end

    def mode_test?
      rack_env == 'test'
    end

    def mode_development?
      rack_env == 'development'
    end

    def mode_production?
      rack_env == 'production'
    end

    def body
      @_body ||= env['rack.input'].read
      #      env['rack.input'].rewindreq.POST #env["body"]
    end

    def path
      req.path
    end

    def form_hash
      StringHash.new(req.POST)
    end

    def body_hash
      @_body_hash ||= if body.empty?
                        {}
                      else
                        # should we check the content type here?
                        begin
                          StringHash.new(MultiJson.load(body))
                        rescue StandardError
                          raise ServiceError, "error in data json format/#{body}/"
                        end
      end
    end

    def get_data(field)
      body_hash['data'] && body_hash['data'][field]
    end

    def format
      @_format
    end

    def query_params
      @_query_params
    end

    def path_params
      @_path_params
    end

    def params
      @_params ||= StringHash.new(@_query_params,@_path_params)
    end

    def post_params
      @_post_params ||= begin
        type = req.media_type
        if type && Rack::Request::FORM_DATA_MEDIA_TYPES.include?(type)
          form_hash
        else
          body_hash
        end
      end
    end

    def path_for(path)
      File.join(RequestMapper.path_root, path)
    end

    def url_for(path)
      req.base_url + path_for(path)
    end

    def req
      @_req
    end

    def verb
      @_verb
    end

    def route_parameters
      @_parameters
    end

    def response
      @_response
    end

    def method
      env['REQUEST_METHOD'].downcase
    end

    def session
      req.session
    end

    # add on the root path
    def full_path(path)
      RequestMapper.full_path(path)
    end

    # the full url of this path.
    def full_url(_path)
      raise 'not yet implemented'
    end

    def redirect(path, status = 302)
      raise ServiceError.new(nil, status, 'Location' => path)
    end

    alias redirect_to redirect

    def request_ip
      req.ip
    end

    # render an erb template with the variables in the controller
    def render_erb(template_name, opts = {})
      self.class.render_erb(template_name, self, opts)
    end

    def render(text, opts = {})
      self.class.render_erb(text, self, opts)
    end

    def rawjson(str)
      RawJsonString.new(str)
    end

    def _get_binding
      binding
    end

    # extract the user and login from the basic authentication
    def get_basic_auth(realm=nil)
      data = env['HTTP_AUTHORIZATION']
      raise AuthorizationError.new('authentication missing',realm) unless data

      type = data[0, 5]
      rest = data[6..-1]

      raise  AuthorizationError.new('wrong authentication method',realm) unless type == 'Basic'
      raise  AuthorizationError.new('username:password missing',realm)   unless rest

      auth_parts = Base64.decode64(rest).split(':')
      login = auth_parts[0]
      password = auth_parts[1]
      [login, password]
    end

    def set_status(value)
      @_response.status = value
    end

    def add_headers(headers)
      @_response.headers.merge!(headers)
    end

    # the following is copied from Rack::Utils
    ESCAPE_HTML = {
      '&' => '&amp;',
      '<' => '&lt;',
      '>' => '&gt;',
      "'" => '&#x27;',
      '"' => '&quot;',
      '/' => '&#x2F;'
    }.freeze

    JS_ESCAPE_MAP = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }.freeze

    ESCAPE_HTML_PATTERN = Regexp.union(*ESCAPE_HTML.keys)

    # Escape ampersands, brackets and quotes to their HTML/XML entities.
    def h(string)
      string.to_s.gsub(ESCAPE_HTML_PATTERN) { |c| ESCAPE_HTML[c] }
    end

    # escape javascript
    def escape_javascript(javascript)
      if javascript
        javascript.gsub(%r{(\|</|\r\n|\342\200\250|\342\200\251|[\n\r"'])}u) { |match| JS_ESCAPE_MAP[match] }
      else
        ''
      end
    end

    # send a (default) error
    def send_error(message, status = nil, headers = nil)
      raise ServiceError.new(message, status, headers)
    end

    def auth_error(*params)
      if params[0].kind_of?(String)
          message = params[0]
          opts = params[1] || {}
      else
          message = nil
          opts = params[-1] || {}
      end
      raise AuthorizationError.new(message,opts[:realm], opts[:type])
    end

    def get_cookie(name)
      cookie_header = env['HTTP_COOKIE']
      cookie_length = name.length
      parts = cookie_header&.split(';')
      value = nil
      parts&.reverse&.each do |cookie|
        cookie.strip!
        if cookie[0..cookie_length] == name + '='
          value = cookie[cookie_length + 1..-1]
          break
        end
      end
      value
    end

    def store_cookie(name, value, opts={})
      cookie_text = String.new("#{name}=#{value}")
      cookie_text << '; Secure'                                  if _opt?(opts,:secure)
      cookie_text << '; HttpOnly'                                if _opt?(opts,:http)
      cookie_text << "; HostOnly=#{_opt(opts,:hostOnly)}"        if _opt?(opts,:hostOnly)
      cookie_text << "; Expires=#{_opt(opts,:expires).httpdate}" if _opt?(opts,:expires)
      cookie_text << "; Max-Age=#{_opt(opts,:max_age)}"          if _opt?(opts,:max_age)
      cookie_text << "; Domain=#{_opt(opts,:domain)}"            if _opt?(opts,:domain)
      cookie_text << "; Path=#{_opt(opts,:path)}"                if _opt?(opts,:path)
      if policy = _opt(opts,:samesite)
        cookie_text << '; SameSite=Strict' if policy.to_s.downcase == 'strict'
        cookie_text << '; SameSite=Lax'    if policy.to_s.downcase == 'lax'
        cookie_text << '; SameSite=None'   if policy.to_s.downcase == 'none'
      end
      @_cookies ||= {}
      @_cookies[name] = cookie_text
      # cookie_header = @_response.headers['Set-Cookie']
      # if cookie_header
      #   cookie_header = cookie_header << "\n" << cookie_text
      # else
      #   cookie_header = cookie_text
      # end
      @_response.headers['Set-Cookie'] = @_cookies.values.join("\n")
      value
    end

    # manage session handling --------------------------------------------------
    # setup the session and retrieve the session_id
    # this id can be used to retrieve and data associated
    # with the session_id in eg: a database or a memory hash
    def get_session_id(session_name, opts = {})
      session_id = get_cookie(session_name)
      session_id || refresh_session_id(session_name, opts)
    end

    # generate an new session_id for the current session
    def refresh_session_id(session_name, opts = {})
      session_id = SecureRandom.hex(32)
      store_session_id(session_name, session_id, opts)
    end

    def _opt?(opts,key)
      opts.key?(key.to_sym) || opts.key?(key.to_s)
    end

    def  _opt(opts,key)
      if opts.key?(key.to_sym)
        opts[key.to_sym]
      else
        opts[key.to_s]
      end
    end

    # set the cookie header that stores the session_id on the browser.
    def store_session_id(session_name, session_id, opts = {})
      store_cookie(session_name, session_id, opts)
    end

    # perform the before hooks.
    def __before(*a)
      self.class._do_before(self, *a)
    end

    # perform the after hooks
    def __after(*a)
      self.class._do_after(self, *a)
    end

    #----------------------------------------------------------------------------------------------------------
    # template methods that can be overwritten

    # a hook used to insert processing for before the method call
    def before(opts); end

    # a hook used to insert processing for after the method call. return a hash containing
    # the response.
    def after(_opts, response)
      response
    end

    #----------------------------------------------------------------------------------------------------------

    def initialize(context, _verb, _path, _parameters)
      @_req            = context.req
      @_env            = req.env
      @_query_params = StringHash.new(req.GET)
      @_path_params  = StringHash.new(context.path_params)
      @_format         = context.format
      @_verb           = _verb
      @_response       = context.response
      @_server_options = context.server_options
      @_parameters     = _parameters
    end

    # do not cache templates in development mode
    def self.no_template_cache
      @_no_template_cache = (Blix::Rest.environment != 'production') if @_no_template_cache.nil?
      @_no_template_cache
    end

    def self.no_template_cache=(val)
      @_no_template_cache = val
    end

    # cache templates here
    def self.erb_templates
      @_erb ||= {}
    end

    def self.set_erb_root(dir)
      @_erb_root = dir
    end

    def self.erb_root
      @_erb_root ||= begin
        root = File.join(Dir.pwd, 'app', 'views')
        raise('use set_erb_root() to specify the location of your views') unless Dir.exist?(root)

        root
      end
    end

    class << self

      # render a string within a layout.
      def render(text, context, opts = {})
        layout_name = opts[:layout]
        path        = opts[:path] || __erb_path || Controller.erb_root

        layout = layout_name && if no_template_cache
                                  ERB.new(File.read(File.join(path, layout_name + '.html.erb')),nil,'-')
                                else
                                  erb_templates[layout_name] ||= ERB.new(File.read(File.join(path, layout_name + '.html.erb')),nil,'-')
        end

        begin
          if layout
            layout.result(context._get_binding { |*_args| text })
          else
            text
          end
        rescue Exception
          ::Blix::Rest.logger <<  $!
          ::Blix::Rest.logger <<  $@
          '*** TEMPLATE ERROR ***'
        end
      end

      def render_erb(name, context, opts = {})
        name        = name.to_s
        layout_name = opts[:layout] && opts[:layout].to_s
        locals      = opts[:locals]
        path        = opts[:erb_dir] || __erb_path || Controller.erb_root

        layout = layout_name && if no_template_cache
                                  ERB.new(File.read(File.join(path, layout_name + '.html.erb')),nil,'-')
                                else
                                  erb_templates[layout_name] ||= ERB.new(File.read(File.join(path, layout_name + '.html.erb')),nil,'-')
        end

        erb = if no_template_cache
                ERB.new(File.read(File.join(path, name + '.html.erb')),nil,'-')
              else
                erb_templates[name] ||= ERB.new(File.read(File.join(path, name + '.html.erb')),nil,'-')
        end

        begin
          bind = context._get_binding
          locals&.each { |k, v| bind.local_variable_set(k, v) } # works from ruby 2.1
          if layout
            layout.result(context._get_binding { |*_args| erb.result(bind) })
          else
            erb.result(bind)
          end
        rescue Exception
          ::Blix::Rest.logger <<  $!
          ::Blix::Rest.logger <<  $@
          '*** TEMPLATE ERROR ***'
        end
      end

      # default method .. will be overridden with erb_path method
      def __erb_path
        nil
      end

      # redefine the __erb_path method for this and derived classes
      def erb_dir(val)
        str = "def self.__erb_path;\"#{val}\";end"
        class_eval str
      end

      def check_format(accept, format)
        return if (format == :json) && accept.nil?  # the majority of cases
        return if (format == :_) && accept.nil?     # assume json by default.

        accept ||= :json
        accept = [accept].flatten
        raise ServiceError, 'invalid format for this request' unless accept.index format
      end

      def route(verb, path, opts = {}, &blk)
        proc = lambda do |context|
          unless opts[:force] && (opts[:accept] == :*)
            check_format(opts[:accept], context.format)
          end
          app = new(context, verb, path, opts)
          begin
            app.before(opts)
            app.__before
            context.response = app.instance_eval( &blk )
          rescue
            raise
          ensure
            app.__after
            app.after(opts, context.response)
            context.response
          end
        end

        RequestMapper.add_path(verb.to_s.upcase, path, opts, &proc)
      end

      def get(*a, &b)
        route 'GET', *a, &b
      end

      def head(*a, &b)
        route 'HEAD', *a, &b
      end

      def post(*a, &b)
        route 'POST', *a, &b
      end

      def put(*a, &b)
        route 'PUT', *a, &b
      end

      def patch(*a, &b)
        route 'PATCH', *a, &b
      end

      def delete(*a, &b)
        route 'DELETE', *a, &b
      end

      def all(*a, &b)
        route 'ALL', *a, &b
      end

      def options(*a, &b)
        route 'OPTIONS', *a, &b
      end


      def _before_hooks
        @_before_hooks ||= {}
      end

      def _after_hooks
        @_after_hooks ||= {}
      end

      def _do_before(ctx, *a)
        superclass._do_before(ctx, *a) if superclass.respond_to? :_do_before
        _before_hooks.each_value{ |h| ctx.instance_eval(&h) }
      end

      def _do_after(ctx, *a)
        _after_hooks.each_value{ |h| ctx.instance_eval(&h) }
        superclass._do_after(ctx, *a) if superclass.respond_to? :_do_after
      end

      # define a before hook for a controller. only one hook can be defined per
      # controller in a single source file.
      def before(&block)
        if block
          file = block.source_location[0]
          warn("warning: before hook already defined in #{file}") if _before_hooks[file]
          _before_hooks[file] = block
        end
      end

      # define an after hook for a controller. only one hook can be defined per
      # controller in a single source file.
      def after(&block)
        if block
          file = block.source_location[0]
          warn("warning: after hook already defined in #{file}") if _after_hooks[file]
          _after_hooks[file] = block
        end
      end

    end

  end

  def self.set_erb_root(*args)
    Controller.set_erb_root(*args)
  end

  def self.no_template_cache=(val)
    Controller.no_template_cache = val
  end
end
