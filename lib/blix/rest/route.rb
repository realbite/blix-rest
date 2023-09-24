module Blix::Rest

  # class used to represent a route and to allow manipulation of the
  # options and path of the route before registrATION

  class Route

    attr_reader :verb, :path, :opts
    alias_method :method, :verb
    alias_method :options, :opts

    def initialize(verb, path, opts)
      @verb = verb.dup
      @path = path
      @opts = opts
    end

    def default_option(key, val)
      opts[key.to_sym] = val unless opts.key?(key) || opts.key?(key.to_sym)
    end

    def path_prefix(prefix)
      prefix = prefix.to_s
      prefix = '/' + prefix unless prefix[0] == '/'
      path.replace( prefix + path) unless path.start_with?(prefix)
    end

    def path=(val)
      path.replace(val.to_s)
    end

  end
end
