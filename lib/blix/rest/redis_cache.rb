# frozen_string_literal: true

require 'redis'
require_relative 'cache'
require_relative 'string_hash'
#
#  options:
#     :expire_secs           - how long store should save data.
#     :reset_expire_on_get   - start the expire timer again on read.

module Blix
  module Rest
    class RedisCache < Cache

      STORE_PREFIX = 'blixcache'

      #---------------------------------------------------------------------------

      # clear all data from the cache
      def clear
        reset
      end

      # retrieve data from the cache
      def get(id)
        key = _key(id)
        str = redis.get(key)
        data = str && begin
                        _decode(str)
                      rescue StandardError
                         redis.del( key)
                         nil
                      end
        redis.expire(key, _opts[:expire_secs]) if data && _opts[:reset_expire_on_get] && _opts.key?(:expire_secs)
        data
      end

      # set data in the cache
      def set(id, data)
        params = {}
        params[:ex] = _opts[:expire_secs] if _opts.key?(:expire_secs)
        redis.set(_key(id), _encode(data), **params)
        data
      end

      #  is key present in the cache
      def key?(id)
        redis.get(_key(id)) != nil
      end

      def delete(id)
        redis.del(_key(id)) > 0
      end

      #---------------------------------------------------------------------------

      def _key(name)
        _prefix + name
      end

      def _opts
        @_opts ||= begin
          o = ::Blix::Rest::StringHash.new
          o[:prefix] = STORE_PREFIX
          o.merge!(params)
          o
        end
      end

      def _prefix
        @_prefix ||= _opts[:prefix]
      end

      # remove all sessions from the store
      def reset(name = nil)
        keys = _all_keys(name)
        redis.del(*keys) unless keys.empty?
      end

      def _all_keys(name = nil)
        redis.keys("#{_prefix}#{name}*") || []
      end

      # the redis session store
      def redis
        @redis ||= begin
          r = Redis.new
          begin
            r.ping
          rescue Exception => e
            Blix::Rest.logger.error "cannot reach redis server:#{e}"
            raise
          end
          r
        end
      end

      # the number of sessions in the store
      def length
        _all_keys.length
      end

      # delete expired sessions from the store. this should be handled
      # automatically by redis if the ttl is set on save correctly
      def cleanup(opts = nil); end

      def _encode(data)
        Marshal.dump(data)
      end

      def _decode(msg)
        Marshal.load(msg)
      end

      def get_expiry_time
        if expire = _opts[:expire_secs] || _opts['expire_secs']
          Time.now - expire
        end
      end

      def get_expiry_secs
        _opts[:expire_secs] || _opts['expire_secs']
      end

    end
  end
end
