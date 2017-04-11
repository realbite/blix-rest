module Realbite::Rest
  
  module Mongo
    
    # A Resource represents a Database Table
    module Validations
      
      PRESENCE = "p"
      FORMAT   = 'f'
      NUMBER   = 'n'
      UNIQUE   = 'u'
      
      #
      module ClassMethods
        
        def inherited(subclass)
          super
          subclass._set_v( _validations)
        end
        
        def _set_v(v)
          @_v = v.dup
        end
        
        def validates_presence_of(*args)
          _validate(PRESENCE,*args)
        end
        
        def validates_format_of(*args)
          _validate(FORMAT,*args)
        end
        
        def validates_numericality_of(*args)
          _validate(NUMBER,*args)
        end
        
        def validates_uniqueness_of(*args)# :name, :scope=>[:site_id]
           _validate(UNIQUE,*args)
        end
                
        def _validations
          @_v ||= []
        end
        
        def _validate(type,*args)
          vals,opts = _get_args(args)
          vals.each{|a| _validations << [type,a.to_s,opts]}
        end
        
        def _get_args(args)
          if args[-1].kind_of? Hash
            opts = args[-1]
            vals = args[0..-2]
          else
            opts = {}
            vals = args
          end
          [vals,opts]
        end
        
      end # ClassMethods
      
      #--------------------------------------------------------------------------------------------------------------
      
      
        
      def perform_validations
        #puts self.class._validations.inspect
        self.class._validations.each do |v|
          field = v[1]
          
          next unless _changed? field
          
          type  = v[0]
          opts  = v[2]
          val   = get(field)
          case type
            when UNIQUE
              selector = {field=>val}
              scope    =  opts[:scope] || []
              scope.each{|s| selector[s] = get(s)}
              found = self.class.first(selector)
              if found && (found != self)
                raise ServiceError, "#{field}:#{val} in not unique" 
              end
              
            when PRESENCE
              raise ServiceError, "#{field} missing" unless get(field)
              
            when FORMAT
              format = opts[:with]
              raise "format missing from validation for #{field}" unless format
              raise ServiceError, "#{field} has invalid format" unless (get(field) =~ format) or ((val==nil) && opts[:allow_nil])
              
            when NUMBER 
              n = get(field)
              if n
                if opts[:only_integer]
                  raise ServiceError, "#{field}:#{val} must be an integer"  unless val.kind_of? Integer
                else
                  raise ServiceError, "#{field}:#{val} must be a number"  unless val.kind_of? Numeric
                end
                if min = opts[:greater_than]
                  raise ServiceError, "#{field} must be greater than #{min}"  unless val > min
                end
                if max = opts[:less_than]
                  raise ServiceError, "#{field} must be less than #{max}"  unless val < max
                end
              else
                 raise ServiceError, "#{field} missing" unless opts[:allow_nil]
              end
              #:only_integer=>true, :allow_nil=>true,  :greater_than=>MIN_PIXELS,:less_than=>MAX_PIXELS
          end  
          
        end
      end
      
      private
      
      
      
      def self.included(mod)
        mod.extend Validations::ClassMethods
      end
      
    end #Resource
    
  end # Mongo
end
