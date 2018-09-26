require 'httpclient'
require 'openssl'

module Blix::Rest
  
  # send requests to a remote REST server and convert the response into a hash
  # or raise an exception. Also allow basic auth headers to be added.
  # FIXME ensure that this is threadsafe!
  class RemoteService
    
    class Request
      attr_reader :verb, :path, :headers, :url
      attr_accessor :body
      
      def initialize(verb,url,path,headers)
        @url = url
        @verb = verb
        @path  = path
        @headers = headers
      end
      
      def full_path
        url + path
      end
      
      def naked_path
        URI(path).path
      end
      
           
      def query_hash
        h = {}
        URI(path).query.split('&').map{|i| i.split('=')}.each do |pair|
          h[pair[0]] = pair[1] 
        end
        h
      end
      
      def replace_query(query_hash)
        query_part = query_hash.to_a.map{|i| i.join('=')}.join('&')
        query_part = '?' + query_part unless query_part.empty?
        @path = naked_path + query_part
      end
      
      def request(conn)
        conn.request(verb,full_path,:body=>body, :header=>headers)
      end
    end
    
    attr_reader :url
    attr_reader :prefix
    
    def initialize(params=nil)
      configure(params) if params
    end
    
    def logger
      @logger 
    end
    
    
    def configure(params)
      @url     = params[:url]
      @prefix  = params[:prefix]
      @logger  = params[:logger]
      
      # ensure that the url has the correct format
      if @url
        raise "invalid url format" unless @url =~ /^http(s)?:\/\/.+$/
      end
      
      # ensure the prefix is in a standard format.
      if @prefix
        @prefix = '/' + @prefix unless @prefix[0,1] == '/'
        @prefix = @prefix[0..-2] if @prefix[-1,1] == '/'
      end
      
      @http_headers = nil
      @server = nil
      self
    end
    
    # return a http/net object for connecting to the server
    def server
      @server ||= begin
        raise "url missing" unless url
        
        uri = URI.parse(url)
        http = HTTPClient.new
        
        if uri.scheme == "https"
          http.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http
      end
    end
    
    # default headers for performing json requests
    def default_http_headers
      @http_headers ||= {
          'Content-Type'=>MIME_TYPE_JSON,
          'Accept'=>MIME_TYPE_JSON,
          'User-Agent'=>"RestClient/#{VERSION}",
      }
    end
    
    # add a basic auth header
    def basic_auth(login,secret)
      default_http_headers.merge!('Authorization'=>"Basic " + Base64.strict_encode64(login + ':' + secret))
    end
    
    # convert the response into a hash or raise an exception if there
    # is an fault.
    def decode_response(resp)
      hash =  (resp.content_type == MIME_TYPE_JSON) && MultiJson.load(resp.body) rescue nil
      code_type = resp.status.to_s[0,1]
      if hash && (code_type == '2')
        hash
      else
        if hash && hash["error"]
          raise ServiceError.new(hash["error"],resp.code)
        else
          raise BadRequestError, resp.code.to_s + ":" + resp.reason.to_s
        end
      end
    end
    
    def request(req)
      start = Time.now
      response = req.request(server)
      if @logger
        @logger.info "#{self.class.name} \"#{req.verb} #{req.path}\" #{response.code} - #{(Time.now-start)*1000.0 }"
      end
      decode_response response
    end
    
    def request_url(path)
      @prefix.to_s + path
    end
    
    def url_for(path)
      url + request_url(path)
    end
    
    #    def get(path)
    #      request{ server.get(request_url(path),nil,default_http_headers)}
    #    end
    #    
    #    def post(path,data={})
    #      request{server.post(request_url(path),{:body=>MultiJson.dump(data)},default_http_headers) }
    #    end
    #    
    #    def put(path,data={})
    #      
    #      request{server.put(request_url(path),{:body=>MultiJson.dump(data)},default_http_headers) }
    #    end
    #    
    #    def delete(path)
    #      request{server.delete(request_url(path),nil,default_http_headers) }
    #    end
    
    def get(path)
      request Request.new('GET',url,request_url(path),default_http_headers)
    end
    
    def post(path,data={})
      req = Request.new('POST',url,request_url(path),default_http_headers)
      req.body = MultiJson.dump(data)
      request req
    end
    
    def put(path,data={})
      req = Request.new('PUT',url,request_url(path),default_http_headers)
      req.body = MultiJson.dump(data)
      request req
    end
    
    def delete(path)
      req = Request.new('DELETE',url,request_url(path),default_http_headers)
      request req
    end
    
    
  end
end