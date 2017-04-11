module Blix::Rest
  
  module ResourceCache

    private
    
    def _cache_hash
      @_cache ||= {}
    end

    def _cache_get(*args,&block)
      field = args[0].to_s
      if block && args.length == 1
        if  _cache?(field)
          _cache_hash[field]
        else
          _cache_hash[field]= block.call
        end
      elsif args.length == 1
        _cache_hash[field]
      elsif  args.length == 2
        if  _cache?(field)
          _cache_hash[field]
        else
          _cache_hash[field]= args[1]
        end
      else
        raise "wrong number of arguments:#{args.length} for 1 or 2"
      end
    end

    def _cache_set(field,val)
      _cache_hash[field.to_s] = val
    end

    def _cache_reset(field)
      _cache_hash.delete field.to_s
    end

    def _cache(field)
      _cache_hash[field.to_s]
    end

    def _cache?(field)
      _cache_hash.key?(field.to_s)
    end
    
  end
  
end