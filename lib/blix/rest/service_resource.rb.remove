module Blix::Rest
  
  
  # class to perform REST calls on s aervice resource
  #. 
  #
  class ServiceResource
    
    def id
      _doc["_id"] || _doc["id"]
    end
    
    def get(field)
      _doc[field.to_s]
    end
    
    def set(field,val)
      _doc[field.to_s] = val
    end
    
    def _doc
      @_doc ||= {}
    end
    
    def _service
      self.class._service
    end
    
    class << self
      def set_service(service)
        @_service = service
      end
      
      def _service
        @_service
      end
      
      def resource_path(path)
        @_path = path
      end
      
      def resource_path
        @_path || '/'
      end
      
      def path_join(*args)
        File.join('/',resource_path,*args)
      end
      
      def new_from_doc(doc)
        obj = allocate
        obj.instance_variable_set(:@_doc, doc)
        obj.instance_variable_set(:@_original_doc, doc.dup)
        obj
      end
      
      def find(id)
        raise "id missing" unless id
        new_from_doc _service.get(path_join(id))["data"]
      end
      
      
      
    end
    
    
  end
end