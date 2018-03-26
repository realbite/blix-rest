require 'base64'
require 'erb'

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
  
  class HashBinding
    
     def initialize(hash)
          @hash = hash
     end
     
     def _get_binding
       b = binding
       @hash.each{|k,v| b.local_variable_set(k,v)}
       b
     end
       
  end
  
  
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
      @_body ||=env['rack.input'].read
      #      env['rack.input'].rewindreq.POST #env["body"] 
    end
    
    def path
      req.path
    end
    
    def form_hash
      StringHash.new.merge req.POST
    end
    
    def body_hash
      @_body_hash ||= if body.empty?
        {}
      else
        # should we check the content type here?
        begin
          StringHash.new.merge(MultiJson.load body)
        rescue
          raise ServiceError, "error in data json format/#{body}/"
        end
      end
    end
    
    def get_data(field)
      body_hash["data"] && body_hash["data"][field]
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
      @_params ||= StringHash.new.merge(@_query_params).merge(@_path_params)
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
      File.join(RequestMapper.path_root,path)
    end
    
    def url_for(path)
      req.base_url + path_for(path)
    end
    
    # forward the call to another service
    def proxy(service,path, opts={})
      if opts[:include_query]
        path = path + '?' + req.query_string
      end
      begin
        ret = case verb
          when 'GET'
          service.get path
          when 'POST'
          service.post path, body_hash
          when 'PUT'
          service.put path, body_hash
          when 'DELETE'
          service.delete path
        end
      rescue WebFrameError=>e
        raise ServiceError.new(e.message,e.code)
      end
      ret["data"]
    end
    
    def req
      @_req
    end
    
    def verb
      @_verb
    end
    
    def session
      req.session
    end
    
    # add on the root path
    def full_path(path)
      path = path[1..-1] if path[0,1] == '/'
      RequestMapper.path_root + path
    end
    
    # the full url of this path.
    def full_url(path)
      
    end
    
    def redirect(path, status=302)
      raise ServiceError.new(nil,status,"Location"=>full_path(path))   
    end
    
    def request_ip
      req.ip
    end
    
    # render an erb template with the variables in the controller
    def render_erb(template_name,opts={})
      Controller.render_erb(template_name,self,opts)
    end
    
    def render(text,opts={})
      Controller.render_erb(text,self,opts)
    end
    
    def _get_binding
      binding
    end
    
    
    # extract the user and login from the basic authentication
    def get_basic_auth
      data = env['HTTP_AUTHORIZATION']
      raise AuthorizationError,"authentication missing" unless data
      type = data[0,5]
      rest = data[6..-1]
      
      raise  AuthorizationError,"wrong authentication method" unless type == "Basic"
      raise  AuthorizationError,"username:password missing"   unless rest
      
      auth_parts = Base64.decode64( rest).split(':')
      login    = auth_parts[0]
      password = auth_parts[1]
      [login,password]
    end
    
    def set_status(value)
      @_response.status = value
    end
    
    def add_headers(headers)
      @_response.headers.merge!(headers)
    end
    
    # the following is copied from Rack::Utils
    ESCAPE_HTML = {
      "&" => "&amp;",
      "<" => "&lt;",
      ">" => "&gt;",
      "'" => "&#x27;",
      '"' => "&quot;",
      "/" => "&#x2F;"
    }
    
    JS_ESCAPE_MAP   =   { '\\' => '\\\\', "</" => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }

    ESCAPE_HTML_PATTERN = Regexp.union(*ESCAPE_HTML.keys)

    # Escape ampersands, brackets and quotes to their HTML/XML entities.
    def h(string)
      string.to_s.gsub(ESCAPE_HTML_PATTERN){|c| ESCAPE_HTML[c] }
    end
 
    # escape javascript
    def escape_javascript(javascript)
      if javascript
         javascript.gsub(/(\|<\/|\r\n|\342\200\250|\342\200\251|[\n\r"'])/u) { |match| JS_ESCAPE_MAP[match] }
      else
         ""
      end
    end
    #----------------------------------------------------------------------------------------------------------
    # template methods that can be overwritten
    
    # a hook used to insert processing for before the method call
    def before(opts)
      
    end
    
    # a hook used to insert processing for after the method call. return a hash containing
    # the response.
    def after(opts,response)
      response
    end
    
    #----------------------------------------------------------------------------------------------------------
    
    def initialize(path_params,params,req,format,verb,response,server_options)
      @_req = req
      @_env = req.env
      @_query_params = StringHash.new.merge(req.GET)
      @_path_params  = StringHash.new.merge(path_params)
      @_format = format
      @_verb = verb
      @_response = response
      @_server_options = server_options
    end
    
    def Controller.no_template_cache
      @_no_template_cache
    end
    
    def Controller.no_template_cache=(val)
      @_no_template_cache = val
    end
    
    # cache templates here
    def Controller.erb_templates
      @_erb ||= {} 
    end
    
    def Controller.set_erb_root(dir)
      @_erb_root = dir
    end
    
    def Controller.erb_root
      @_erb_root || raise( "set_erb_root must be set on the Rest::Controller to use erb")
    end
    
    # render a string within a layout.
    def Controller.render(text,context,opts={})
      layout_name = opts[:layout]
      
      layout =  layout_name && if no_template_cache
        ERB.new( File.read(File.join(erb_root, layout_name + ".html.erb")))
      else
        erb_templates[layout_name] ||= ERB.new( File.read(File.join(erb_root, layout_name + ".html.erb")))
      end
      
      begin
        if layout
          layout.result(context._get_binding{|*args| text })
        else
          text
        end
      rescue Exception
        puts $!
        puts $@
        "*** TEMPLATE ERROR ***"
      end
    end
    
    def Controller.render_erb(name,context,opts={})
      name        = name.to_s
      layout_name = opts[:layout]
      locals      = opts[:locals]
      
      layout =  layout_name && if no_template_cache
        ERB.new( File.read(File.join(erb_root, layout_name + ".html.erb")))
      else
        erb_templates[layout_name] ||= ERB.new( File.read(File.join(erb_root, layout_name + ".html.erb")))
      end
      
      erb = if no_template_cache
        ERB.new( File.read(File.join(erb_root, name + ".html.erb")))
      else
        erb_templates[name] ||= ERB.new( File.read(File.join(erb_root, name + ".html.erb")))
      end
      
      begin
        if layout
          layout.result(context._get_binding{|*args| erb.result(context._get_binding)})
        else
           bind = context._get_binding
           locals.each{|k,v| bind.local_variable_set(k,v)} if locals
           erb.result(bind)
        end
      rescue Exception
        puts $!
        puts $@
        "*** TEMPLATE ERROR ***"
      end
    end
    
    
    class << self

      def check_format(accept,format)
        return if (format==:json) && (accept==nil)  # the majority of cases
        accept ||= :json
        accept = [accept].flatten
        raise ServiceError,"invalid format for this request" unless accept.index format
      end
      
      def route( verb ,path, opts = {}, &blk)
        proc = lambda do |_path_params,_params,_req,_format,_response,server_options | 
          self.check_format(opts[:accept],_format)
          app = self.new(_path_params,_params,_req,_format,verb,_response,server_options)
          app.before(opts)
          response = app.instance_eval &blk
          app.after(opts,response)
        end
        
        RequestMapper.add_path(verb.to_s.upcase,path,opts,&proc) 
      end
      
      def get(*a, &b)  route 'GET', *a, &b end
      def post(*a, &b) route 'POST', *a, &b end
      def put(*a, &b) route 'PUT', *a, &b end
      def delete(*a, &b) route 'DELETE', *a, &b end
      
    end
    
  end
  
  def self.set_erb_root(*args)
     Controller.set_erb_root( *args )
  end
  
  def self.no_template_cache=(val)
     Controller.no_template_cache=val
  end
  
end