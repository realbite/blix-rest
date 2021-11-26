# frozen_string_literal: true

require 'redis'
# require 'msgpack'

#
#  options:
#     :expire_secs           - how long store should save data.
#     :reset_expire_on_get   - start the expire timer again on read.

module Blix
  class RedisStore

    attr_reader :_opts, :_prefix

    STORE_PREFIX = 'session'

    def initialize(opts = {})
      @_opts = ::Blix::Rest::StringHash.new
      @_opts[:prefix] = STORE_PREFIX
      @_opts.merge!(opts)
      @_prefix = _opts[:prefix]
    end

    #-----------------------------------------------------------------------------

    # retrieve raw data and reset the expire time.
    def get_data(id)
      k = _key(id)
      data = redis.get(k)
      redis.expire(k, _opts[:expire_secs]) if data && _opts[:reset_expire_on_get] && _opts.key?(:expire_secs)
      data
    end

    # store raw data
    def store_data(id, data)
      params = {}
      params[:ex] = _opts[:expire_secs] if _opts.key?(:expire_secs)
      redis.set(_key(id), data, **params)
      data
    end

    # delete a record from the store
    def delete_data(id)
      redis.del(_key(id))
    end

    # if decoding does not succeed then delete the data
    # and return nil.
    def get_hash(id)
      str = get_data(id)
      str && begin
        _decode(str)
      rescue Exception =>e
        delete_data(id)
        nil
      end
    end

    def store_hash(id,hash)
      store_data(id, _encode(hash || {}))
      hash
    end

    # retrieve a session hash.
    def get_session(id,opts={})
      str = redis.get(_key(id))
      opts = ::Blix::Rest::StringHash.new.merge(opts)
      hash = begin
        str && ::Blix::Rest::StringHash.new(_decode(str))
      rescue
        redis.del(_key(id))
        hash = nil
      end
      if hash && (min_time = get_expiry_time(opts)) && (hash['_last_access'] < min_time)
        delete_session(id)
        raise SessionExpiredError
      end
      raise SessionExpiredError if !hash && opts[:nocreate]

      hash ||= ::Blix::Rest::StringHash.new
      hash['_last_access'] = Time.now
      hash
    end

    # store a session hash
    def store_session(id, hash)
      params = {}
      params[:ex] = _opts[:expire_secs] if _opts.key?(:expire_secs)
      hash ||= {}
      hash['_last_access'] = Time.now
      redis.set(_key(id), _encode(hash), **params)
      hash
    end

    # delete a seession from the store
    def delete_session(id)
      redis.del(_key(id))
    end

    def _key(name)
      _prefix + name
    end



    #-----------------------------------------------------------------------------

    # remove all sessions from the store
    def reset(name=nil)
      keys = _all_keys(name)
      redis.del(*keys) unless keys.empty?
    end

    def _all_keys(name=nil)
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

    # redis takes care of this operation
    def run_cleanup_thread(opts = nil); end

    # redis takes care of this operation
    def stop_cleanup_thread(_opts = nil); end

    def cleaning?
      false
    end

    private

    def get_expiry_time(opts)
      if expire = opts[:expire_secs] || opts['expire_secs']
        Time.now - expire
      end
    end

    def get_expiry_secs(opts)
      opts[:expire_secs] || opts['expire_secs']
    end

  end
end
