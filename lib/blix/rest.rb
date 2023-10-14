require 'base64'
require 'logger'
require 'time'
require 'cgi'
require 'rack'

module Blix
  module Rest
    MIME_TYPE_JSON = 'application/json'.freeze
    # EXPIRED_TOKEN_MESSAGE = 'token expired'
    # INVALID_TOKEN_MESSAGE = 'invalid token'

    CONTENT_TYPE      = 'content-type'.freeze
    CONTENT_TYPE_JSON = 'application/json'.freeze
    CONTENT_TYPE_HTML = 'text/html; charset=utf-8'.freeze
    CONTENT_TYPE_XML  = 'application/xml'.freeze
    AUTH_HEADER       = 'www-authenticate'.freeze
    CACHE_CONTROL     = 'cache-control'.freeze
    CACHE_NO_STORE    = 'no-store'.freeze
    PRAGMA            = 'pragma'.freeze
    NO_CACHE          = 'no-cache'.freeze
    URL_ENCODED       = %r{^application/x-www-form-urlencoded}.freeze
    JSON_ENCODED      = %r{^application/json}.freeze # NOTE: "text/json" and "text/javascript" are deprecated forms
    HTML_ENCODED      = %r{^text/html}.freeze
    XML_ENCODED       =  %r{^application/xml}.freeze

    HTTP_DATE_FORMAT  = '%a, %d %b %Y %H:%M:%S GMT'.freeze
    HTTP_VERBS        = %w[GET HEAD POST PUT DELETE OPTIONS PATCH].freeze
    HTTP_BODY_VERBS   = %w[POST PUT PATCH].freeze

    # the test/development/production environment
    def self.environment
      @_environment ||= ENV['RACK_ENV'] || 'development'
    end

    def self.environment?(val)
      environment == val.to_s
    end

    def self.environment=(val)
      @_environment = val.to_s
    end

    def self.logger=(val)
      @_logger = val
    end

    def self.cache_disabled
      @_cache_disabled
    end

    def self.disable_cache
      @_cache_disabled = true
    end

    def self.logger
      @_logger ||= begin
        l = Logger.new(STDOUT)
        unless l.respond_to? :write   # common logger needs a write method
          def l.write(*args)
            self.<<(*args)
          end
        end
        l
      end
    end


    class BinaryData < String
      def as_json(*_a)
        { 'base64Binary' => Base64.encode64(self) }
      end

      def to_json(*a)
        as_json.to_json(*a)
      end
    end

    # interpret payload string as json
    class RawJsonString < String

      def as_json(*_a)
        self
      end

      def to_json(*a)
        as_json.to_json(*a)
      end
    end

    class BadRequestError < StandardError; end

    class ServiceError < StandardError
      attr_reader :status
      attr_reader :headers

      def initialize(message, status = nil, headers = nil)
        super(message || "")
        @status = status.to_i || 406
        @headers = headers
      end

      def to_i
        @status
      end

    end

    class RawResponse < StandardError
      attr_reader :status
      attr_reader :headers
      attr_reader :content

      def initialize(message, status = nil, headers = nil)
        super(message || "")
        @status  = status
        @headers = headers
        @content = message
      end
    end

    class AuthorizationError < StandardError
      attr_reader :realm, :type
      def initialize(message=nil, realm=nil, type=nil)
        super(message || "")
        @realm = realm || 'rest'
        @type = type || 'Basic'
      end
    end
  end
end

class NilClass
  def empty?
    true
  end
end

# common classes
require 'multi_json'
require 'logger'
require 'blix/rest/version'
require 'blix/rest/string_hash'

# client classes
# require 'blix/rest/remote_service'
# require 'blix/rest/web_frame_service'
# require 'blix/rest/service'
# require 'blix/rest/service_resource'

# provider classes
require 'rack'
require 'blix/rest/response'
require 'blix/rest/format_parser'
require 'blix/rest/request_mapper'
require 'blix/rest/cache'
require 'blix/rest/server'
require 'blix/rest/route'
require 'blix/rest/controller'
# require 'blix/rest/provider_controller'

# ensure that that times are sent in the correct json format
class Time
  def as_json(*_a)
    utc.iso8601
  end

  def to_json(*a)
    as_json.to_json(*a)
  end
end
