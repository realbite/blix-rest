module Blix::Rest
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
