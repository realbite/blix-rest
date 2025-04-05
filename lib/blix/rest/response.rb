# pass a response object to the controller to set
# header status and content.

unless defined?(Rack::Headers)
  class Rack::Headers < Hash; end
end

module Blix::Rest


  class Response

    attr_accessor :status
    attr_reader   :headers
    attr_accessor :content

    def initialize
      @status  = 200
      @headers  = Rack::Headers.new
      @content = nil
    end

    def set(status,content=nil,headers=nil)
      @status = status if status
      @content = [String.new(content)] if content
      @headers.merge!(headers) if headers
    end

    def set_options(options={})
      @status = options[:status].to_i if options[:status]
      @headers.merge!(options[:headers]) if options[:headers]
      @headers['content-type'] = options[:content_type] if options[:content_type]
    end

  end
end
