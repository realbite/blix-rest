module Blix::Rest

  # cache server responses
  class Cache

    attr_reader :params

    def initialize(params={})
      @params = params
    end

    def [](key)
      get(key)
    end

    def []=(key,data)
      set(key, data)
    end

    #--------------- redefine these methods ..

    # clear all data from the cache
    def clear

    end

    # retrieve data from the cache
    def get(key)

    end

   # set data in the cache
    def set(key, data)

    end

    #  is key present in the cache
    def key?(key)

    end

    def delete(key)

    end

    #---------------------------------------------------------------------------


  end

  # implement cache as a simple ruby hash
  class MemoryCache < Cache

    def cache
      @cache ||= {}
    end

    def get(key)
      cache[key]
    end

    def set(key, data)
      cache[key] = data
    end

    def clear
      cache.clear
    end

    def key?(key)
      cache.key?(key)
    end

    def delete(key)
      cache.delete(key)
    end

  end
end
