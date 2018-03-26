module Blix::Rest
  
  class RequestMapperError < StandardError; end
  
  # register routes with this class and then we can match paths to 
  # these routes and return an associated block and parameters.
  class RequestMapper
    
    WILD_PLACEHOLDER = '/'
    PATH_SEP         = '/'
    STAR_PLACEHOLDER = '*'
    
    class TableNode
      attr_accessor :blk
      attr_reader   :value
      attr_accessor :opts
      attr_reader   :parameter
      
      def initialize(name)
        @children = {}
        if name[0,1] == ':'
          @parameter = name[1..-1].to_sym
          @value     = WILD_PLACEHOLDER
        else
          @value    = name
        end
      end
      
      def [](k)
        @children[k]
      end
      
      def []=(k,v)
        @children[k] = v
      end
      
    end
    
    class << self 
      
      def set_path_root(root)
        root = root.to_s
        root = "/" + root if root[0,1] != '/'
        root = root + '/' if root[-1,1] != '/'
        @path_root = root
        @path_root_length = @path_root.length - 1
      end
      
      def path_root
        @path_root || '/'
      end
      
      def path_root_length
        @path_root_length
      end
      
      def locations
        @locations ||= Hash.new {|h,k| h[k] = []}
      end
      
      def table
        @table ||= compile
      end
      
      # used for testing only !!
      def reset(vals=nil)
        save = [@table && @table.dup, @locations && @locations.dup, @path_root && @path_root.dup, @path_root_length]
        if vals
          @table     = vals[0]
          @locations = vals[1]
          @path_root = vals[2]
          @path_root_length =vals[3]
        else
          @table     = nil
          @locations = nil
          @path_root = nil
          @path_root_length = 0
        end
        save
      end
      
      # compile routes into a tree structure for easy lookup
      def compile
        @table = Hash.new {|h,k| h[k] = TableNode.new("")}
        locations.each do |verb,routes|
          routes.each do |info|
            verb,path,opts,blk = info
            parts = path.split(PATH_SEP)
            current = @table[verb]
            parts.each_with_index do |section,idx|
              node = TableNode.new(section)
              # check that a wildstar is the last element.
              if (section == STAR_PLACEHOLDER) && (idx < (parts.length-1))
                raise RequestMapperError,"do not add a path after the * in #{path}"
              end
              
              # check that wild card match in name
              if current[node.value]
                if (node.value == WILD_PLACEHOLDER) && (node.parameter !=  current[node.value].parameter)
                  raise RequestMapperError, "parameter mismatch in route=#{path}, expected #{current[node.value].parameter} but got #{node.parameter}"
                end
                
              else
                current[node.value] = node
              end
              current = current[node.value]
            end
            current.blk = blk
            current.opts = opts
          end
        end
        @table
      end
      
      # declare a route
      def add_path( verb, path, opts = {}, &blk)   
        path = path[1..-1] if path[0,1] == PATH_SEP 
        RequestMapper.locations[verb] << [verb,path,opts,blk]
        @table = nil # force recompile
      end
      
      # match a given path to  declared route.
      def match(verb,path)
        path = PATH_SEP + path if path[0,1] != PATH_SEP  # ensure a leading slash on path

        path = path[path_root_length..-1] if path_root_length.to_i > 0
        if path
           path = path[1..-1] if path[0,1] == PATH_SEP              # remove the leading slash
        else
           return [nil,{}]
        end
        
        parts = path.split(PATH_SEP)
        current = table[verb]
        limit   = parts.length - 1 
        parameters = StringHash.new
        # handle the root node here
        if path==""
          return  [current.blk,parameters]
        end
        
        parts.each_with_index do |section,idx|
          format  = File.extname(section)
          section = File.basename(section,format)
          
          parameters['format'] = format[1..-1].to_sym if (idx == limit) && !(format.empty?) 
          
          last    = current
          current = current[section]
          
          if current
            if idx == limit # the last section
              return  [current.blk,parameters]
            end
          else
            current = last[WILD_PLACEHOLDER]
            if current
              parameters[current.parameter.to_s] = section
              if idx == limit # the last section
                return [current.blk,parameters]
              end
            else
              # 
              current = last[STAR_PLACEHOLDER]
              if current
                parameters['wildpath'] = '/' + parts[idx..-1].join('/')
                return [current.blk,parameters]
              else
                return [nil,{}]
              end
            end
          end
        end
        return [nil,{}]
      end
      
      # match a path to a route and call any associated block with the extracted parameters.
      def process(verb,path)
        blk, params = match(verb,path)
        blk && blk.call(params)
      end
      
      def routes
        hash = {}
        puts "----------------------------"
        locations.values.each do |group|
          group.each do |route|
            verb = route[0]
            options = route[2]
            options_string = ""
            unless options.empty?
              options_string = " " + options.inspect.to_s
            end
            path = "/" + route[1]
            hash[path] ||={}
            hash[path][verb] = options_string
          end
        end
        list = hash.to_a
        list.sort!{|a,b| a[0]<=> b[0]}
        str = ""
        list.each do |route|
          pairs = route[1]
          ['GET','POST','PUT','DELETE'].each do |verb|
            if route[1].key? verb
              str << verb << "\t" << route[0] << route[1][verb] << "\n"
            end
          end
          str << "\n"
        end
        str
      end
      
      
      
    end
  end # RequestMapper
  
  def self.set_path_root(*args)
     RequestMapper.set_path_root( *args )
  end
  
end # Rest