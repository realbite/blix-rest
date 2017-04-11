module Realbite::Rest
  
  module Mongo
    
    # A Resource represents a Database Table
    module Resource
      
      include ::Realbite::Rest::ResourceCache
      #
      module ClassMethods
        
        def inherited(subclass)
          super
          subclass._set_attributes( _safe_attributes, _table)
        end
        
        def _set_attributes(safe,name)
          @_attributes = safe.dup
          @_table = name.dup
        end
        
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
        
        def set_times
          str = <<-RUBY
        def _set_times
          t = Time.now
          set(:modified_at,t)
          set(:created_at,t) if new?
        end
        RUBY
          puts str if $VERBOSE
          class_eval str 
        end
        
        def property(name,*args)
          str = <<-RUBY
        def #{name}
          get(:#{name})
        end
        def #{name}=(val)
          RUBY
          
          str += "          val = val && BSON::ObjectId.from_string(val.to_s)\n" if nam.to_s[-3,3] == '_id'
          
          str += <<-RUBY
          set(:#{name},val)
        end
          RUBY
          
          puts str if $VERBOSE
          class_eval str 
        end
        
        # a slow implementation of count !!!!
        def count(params=nil)
          if params
            where(params).length
          else
            all.length
          end
        end
        
        # get all the documents
        def all(params=nil)
          if params
            where(params)
          else
            Database.all_docs(_table).map{|bson| _new(bson)}
          end
        end
        
        # remove documents from the table
        def remove(conditions={})
          Database.remove(_table,conditions)
        end
        
        def get(id)
          find(id)
        end
        
        # find a document by id
        def find(id)
          unless id.kind_of? BSON::ObjectId
            id = BSON::ObjectId.from_string(id.to_s)
          end
          hash = Database.find(_table,{"_id"=>id}).first
          hash && _new(hash)
        end
        
        # find document and raise error if not found
        def find!(id)
          o = find(id)
          raise ServiceError, "invalid id" unless o
          o
        end
        
        # list of documents with given field
        def find_by(field,name)
          Database.find(_table,{field.to_s=>name}).map{|bson| _new(bson)}
        end
        
        # find documents matching the conditions
        def where(cond={})
          Database.find(_table,cond).map{|bson| _new(bson)}
        end
        
        def raw_where(cond={})
          Database.find(_table,cond)
        end
        
        def first(cond={})
          where(cond).first
        end
        
        def create(params={})
          o = _new(params)
          o.save()
          o
        end
        
        def _new(params={})
          o = allocate
          o._initialize(params)
          o
        end
        # create object using accessors to set values
        def create!(params={})
          o = allocate
          o.set_all_attributes(params)
          o.save()
          o
        end
      end # ClassMethods
      
      #--------------------------------------------------------------------------------------------------------------
      
      def initialize(params={})
        _initialize(params)
      end
      
      def _initialize(params={})
        @_original_doc = params.dup
        @_doc = params
        @_cache = {}
      end
      
      def reload
        raise "attempt to reload an unsaved resource!" unless id 
        @_cache.clear
        @_doc = Database.find(_table,{"_id"=>id}).first
        @_original_doc = @_doc.dup
        self
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
        h["id"] = h.delete("_id")
        h
      end
      
      # the document id
      def id
        _doc["_id"]
      end
      
      
      # hook to add validation/processing before a save
      def before_save
        
      end
      
      def after_save
        
      end
      
      def _set_times
      end
      
      # hook to add validation/processing before a destroy
      def before_destroy
        
      end
      
      def after_destroy
      end
      
      def perform_validations
        
      end
      
      def new?
        !@_original_doc.key?("_id")
      end
      
      def get_original(key)
        _original_doc[key.to_s]
      end
      
      def _changed?(key)
        _doc[key.to_s] != _original_doc[key.to_s]
      end	     
      
      
      # save the document. if this is a new document then generate an id
      def save
        _set_times
        before_save
        perform_validations
        ret = save!
        after_save
        ret
      end
      
      # save without the hooks
      def save!
        if id
          Database.update(_table,{"_id"=>id},_doc)
        else
          _doc["_id"] = BSON::ObjectId.new
          begin
             Database.insert(_table,_doc)
          rescue
            _doc["_id"] = nil
            raise
          end
        end   
      end
      
      # destroy this resource from the database
      def destroy
        if id
          before_destroy
          Database.remove(_table,{"_id"=>id})
          _doc.clear
          freeze
          after_destroy
          true
        else
          false
        end
      end
      
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
          k = k.to_s
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
       (self.class == other.class) && (self.id == other.id) && self.id && other.id
      end
      
      private
      
      # the document
      def _doc
        @_doc ||= {}
      end
      
      def _original_doc
        @_original_doc
      end
      
      # the table name at instance level
      def _table
        self.class._table
      end
      
      def self.included(mod)
        mod.extend Resource::ClassMethods
        mod.extend Relationships
      end
      
    end #Resource
    
  end # Mongo
end
