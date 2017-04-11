module Blix::Rest
  
  class StringHash < Hash
    def [](k)
      super(k.to_s)
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