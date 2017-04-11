module Realbite::Rest
  
  module Mongo
  
        
    # A Resource represents a Database Table
    module SubResource
      
      include ::Realbite::Rest::ResourceCache
      #
      module ClassMethods
        
        def safe_attributes(*list)
          @_attributes ||= []
          @_attributes += list.map{|i| i.to_s}
        end
        
        def _safe_attributes
          @_attributes || []
        end
        
        def set_table(name)
          @_table = name
        end
        
        def _table
          @_table
        end
        
        def property(name,*args)
          str = <<-RUBY
        def #{name}
          get(:#{name})
        end
        def #{name}=(val)
          RUBY

          str += "          val = val && BSON::ObjectId.from_string(val.to_s)\n" if name[-3,3] == '_id'
        
          str += <<-RUBY
          set(:#{name},val)
        end
          RUBY

          puts str if $VERBOSE
          class_eval str 
        end
        
        def create(params={})
          o = _new(params)
          o
        end
        
        def _new(params={},parent=nil)
          o = allocate
          o._initialize(params,parent)
          o
        end
        
        # create object using accessors to set values
        def create!(params={})
          o = allocate
          o.set_all_attributes(params)
          o
        end
        
      end # ClassMethods1
      
      
      
      #--------------------------------------------------------------------------------------------------------------
      
      def initialize(params={},parent=nil)
        _initialize(params,parent)
      end
      
      def _initialize(params={},parent=nil)
	      @_parent = parent
        @_original_doc = params.dup
        @_doc = params
      end
      
      def _parent
	      @_parent
      end
   
       # get the value of a field
      def get(field)
        _doc[field.to_s]
      end
      
      # set the value of a field
      def set(field,value)
        _doc[field.to_s] = value
      end
      
      # convert to hash for json
      def as_json(*args)
        h = _doc.merge("_type"=>_table)
        #h["id"] = h.delete("_id")
        h
      end
      
      def to_doc
         _doc
      end
      
      # the document id
      #      def id
      #        _doc["_id"]
      #      end
      
      
      # hook to add validation/processing before a save
      #      def before_save
      #        
      #      end
      #      
      #      def after_save
      #        
      #      end
      #      
      #      # hook to add validation/processing before a destroy
      #      def before_destroy
      #        
      #      end
      #      
      #      def new?
      #        !@_original_doc.key?("_id")
      #      end
      
      
      # save the document. if this is a new document then generate an id
      #      def save
      #        before_save
      #        ret = if id
      #          Database.update(_table,{"_id"=>id},_doc)
      #        else
      #          _doc["_id"] = BSON::ObjectId.new
      #          Database.insert(_table,_doc)
      #        end
      #        after_save
      #        ret
      #      end
      #      
      #      # destroy this resource from the database
      #      def destroy
      #        before_destroy
      #        if id
      #          Database.remove(_table,{"_id"=>id})
      #          _doc.clear
      #          freeze
      #          true
      #        end
      #      end
      
      def set_safe_attributes(hash)
        hash.each do |k,v|
          next if k=="_type"
          next if (k=="id") || (k=="_id")
          if self.class._safe_attributes.include? k
            m = self.method("#{k}=") rescue nil
            if m
              m.call(v)
            else
              self.set(k,v)
            end
          else
            m = self.method("#{k}") rescue nil
            if m
              ov = m.call()
            else
              ov = self.get(k)
            end 
            if ov != v
              raise ServiceError,"attempt to modify protected attribute:#{k}"
            end
          end
        end
        self
      end
      
      def set_all_attributes(hash)
        hash.each do |k,v|
          next if k=="_type"
          next if (k=="id") || (k=="_id")
          m = self.method("#{k}=") rescue nil
          if m
            m.call(v)
          else
            self.set(k,v)
          end
        end
        self
      end
      
      def ==(other)
        (self.class == other.class) && (self.to_doc == other.to_doc)
      end
      
      private
      
          
      # the document
      def _doc
        @_doc ||= {}
      end
      
      def _original_doc
        @_original_doc
end

         def _changed?(key)
	     _doc[key.to_s] != _original_doc[key.to_s]
       end	     
      
      
      # the table name at instance level
      def _table
        self.class._table
      end
      
      def self.included(mod)
        mod.extend SubResource::ClassMethods
        mod.extend Relationships
      end
      
    end #Resource
    
  end # Mongo
end
