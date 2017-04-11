module Realbite::Rest
  
  module Mongo
    module Relationships
      
      
      
      def belongs_to(name,*args)
        model,opts = extract_model_and_options(args)
        
        attr = opts.delete(:child_key) || "#{name}_id"
        parent = model || construct_klass(name)
        
        str = <<-RUBY
        
        def #{attr}
          get(:#{attr})
        end
        def #{attr}=(val)
          val = val && BSON::ObjectId.from_string(val.to_s)
          _cache_reset(:#{name})
          set(:#{attr},val)
        end

        def #{name}
          _cache_get(:#{name}, get(:#{attr}) && #{parent}.find(get(:#{attr}) ))
        end
        
        def #{name}=(val)
          set(:#{attr},val && val.id)
          _cache_set(:#{name},val)
        end
        RUBY
        
        puts str if $VERBOSE
        class_eval str
        
      end
      
      private
      
      def extract_model_and_options(args)
        model = args.shift      
        if model.kind_of? Hash
          opts = model
          model = nil
        else
          opts = args.shift || {}
        end
        return model,opts
      end
      
      # construct a klass from a name
      def construct_klass(name)
        name.to_s.split('_').map{|i|i.capitalize}.join
      end
      
      
    end
    
    
    
  end
end