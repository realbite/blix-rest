module Blix::Rest

  class StringHash < Hash
    def [](k)
      super(k.to_s)
    end

    def get(k,default=nil)
      if  key?(k.to_s)
        self[k]
      else
        default
      end
    end


    def []=(k,v)
      super(k.to_s,v)
    end

    def include?(k)
      super(k.to_s)
    end

    def delete(k)
      super(k.to_s)
    end
  end
end
