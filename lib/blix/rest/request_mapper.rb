# frozen_string_literal: true
require 'thread'

module Blix::Rest
  class RequestMapperError < StandardError; end

  # register routes with this class and then we can match paths to
  # these routes and return an associated block and parameters.
  class RequestMapper

    @@mutex = Mutex.new

    WILD_PLACEHOLDER = '/'
    PATH_SEP         = '/'
    STAR_PLACEHOLDER = '*'

    # the TableNode class is used to build a tree structure to
    # represent the routes.
    #
    class TableNode

      attr_accessor :blk
      attr_reader   :value
      attr_accessor :opts
      attr_reader   :parameter
      attr_reader   :children
      attr_accessor :extract_format

      def initialize(name)
        @children = {}
        @value, @parameter = parse_name(name)
        @extract_format = true
      end

      def [](k)
        @children[k]
      end

      def []=(k, v)
        @children[k] = v
      end

      private

      def parse_name(name)
        case name[0]
        when ':'
          [WILD_PLACEHOLDER, name[1..].to_sym]
        when '*'
          [STAR_PLACEHOLDER, name[1..].empty? ? :wildpath : name[1..].to_sym]
        else
          [name, nil]
        end
      end

    end

    class << self

      # the root always starts with '/' and finishes with '/'
      def set_path_root(root)
        root = root.to_s
        root = '/' + root unless root.start_with?('/')
        root += '/' unless root.end_with?('/')
        @path_root = root
        @path_root_length = @path_root.length - 1
      end

      # if the path_root has not been set then return '/'
      def path_root
        @path_root || '/'
      end

      # return 0 if the path_root has not been set   
      def path_root_length
        @path_root_length || 0
      end

      def full_path(path)
        path = path[1..-1] if path[0, 1] == '/'
        path_root + path
      end

      # ensure that absolute path is the  full path
      def ensure_full_path(path)
        if path[0, 1] == '/' && (path_root_length>0) && path[0, path_root_length] != path_root[0, path_root_length]
          path = path_root + path[1..-1]
        end
        path
      end

      def locations
        @locations ||= Hash.new { |h, k| h[k] = [] }
      end

      def table
        # compile the table in one thread only.
        @table || @@mutex.synchronize{@table ||= compile}
      end

      def dump
        table.each do |k, v|
          puts k
          dump_node(v, 1)
        end
      end

      def dump_node(item, indent = 0)
        puts "#{' ' * indent} value=#{item.value.inspect} opts=#{item.opts.inspect} params=#{item.parameter.inspect}"
        item.children.each_value { |c| dump_node(c, indent + 1) }
      end

      # used for testing only !!
      def reset(vals = nil)
        save = [@table&.dup, @locations&.dup, @path_root&.dup, @path_root_length]
        if vals
          @table     = vals[0]
          @locations = vals[1]
          @path_root = vals[2]
          @path_root_length = vals[3]
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
        @table = Hash.new { |h, k| h[k] = TableNode.new('') }
        locations.each do |verb, routes|
          routes.each do |info|
            verb, path, opts, blk = info
            parts = path.split(PATH_SEP)
            current = @table[verb]
            parts.each_with_index do |section, idx|
              node = TableNode.new(section)
              # check that a wildstar is the last element.
              if (section[0] == STAR_PLACEHOLDER) && (idx < (parts.length - 1))
                raise RequestMapperError, "do not add a path after the * in #{path}"
              end

              # check that wild card match in name
              if current[node.value]
                if (node.value == WILD_PLACEHOLDER) && (node.parameter != current[node.value].parameter)
                  raise RequestMapperError, "parameter mismatch in route=#{path}, expected #{current[node.value].parameter} but got #{node.parameter}"
                end

              else
                current[node.value] = node
              end
              current = current[node.value]
            end
            current.blk = blk
            current.opts = opts || {}
            current.extract_format = opts[:extension] if opts.key?(:extension)
          end
        end
        @table
      end

      # declare a route
      def add_path(verb, path, opts = {}, &blk)
        path = path[1..-1] if path[0, 1] == PATH_SEP
        RequestMapper.locations[verb] << [verb, path, opts, blk]
        @table = nil # force recompile
        true
      end

      # match a given path to  declared route.
      def match(verb, path)
        path = PATH_SEP + path if path[0, 1] != PATH_SEP # ensure a leading slash on path

        path = path[path_root_length..-1] if (path_root_length.to_i > 0) #&& (path[0,path_root_length] == path_root)
        if path
          path = path[1..-1] if path[0, 1] == PATH_SEP # remove the leading slash
        else
          return [nil, {}, nil]
        end

        parameters = StringHash.new

        parts = path.split(PATH_SEP)
        current = table[verb]
        limit   = parts.length - 1

        # handle the root node here
        if path == ''
          if current.blk
            return [current.blk, parameters, current.opts]
          elsif (havewild = current[STAR_PLACEHOLDER])
            parameters[havewild.parameter.to_s] = '/'
            return [havewild.blk, parameters, havewild.opts]
          else
            return [nil, {}, nil]
          end
        end

        parts.each_with_index do |section, idx|
          # first save the last node that we used
          # before updating the current node.

          last = current # table nodes

          # check to see if there is a path which includes a format part
          # only on the last section
          if idx == limit
            if last[section]
              current = last[section]
            else
              format  = File.extname(section)
              base    = File.basename(section, format)
              current = last[base]
              if current
                parameters['format'] = format[1..-1].to_sym # !format.empty?
                section = base
              end
            end
          else
            current = last[section]
          end

          # if current is set here that means that this section matches a fixed
          # part of the route.
          if current

            # if this is the last section then we have to decide here if we
            # have a valid result..
            # .. if we have a block then fine ..
            # .. if there is a wildpath foloowing then fine ..
            # .. otherwise an error !

            if idx == limit # the last section of path
              if current.blk
                return [current.blk, parameters, current.opts]
              elsif (havewild = current[STAR_PLACEHOLDER])
                parameters[havewild.parameter.to_s] = '/'
                return [havewild.blk, parameters, havewild.opts, true]
              else
                return [nil, {}, nil]
              end
            end
          else

            # this section is  not part of a static path so
            # check if we have a path variable first ..

            current = last[WILD_PLACEHOLDER]
            if current

              # yes this is a path variable section
              if idx == limit

                # the last section of request -
                if current.extract_format
                  format  = File.extname(section)
                  base    = File.basename(section, format)
                  parameters[current.parameter.to_s] = base
                  parameters['format'] = format[1..-1].to_sym unless format.empty?
                else
                  parameters[current.parameter.to_s] = section
                end

                # check if we have a valid block otherwise see if
                # a wild path follows.

                if current.blk
                  return [current.blk, parameters, current.opts]
                elsif (havewild = current[STAR_PLACEHOLDER])
                  parameters[havewild.parameter.to_s] = '/'
                  return [havewild.blk, parameters, havewild.opts, true]
                else
                  return [nil, {}, nil]
                end

              else
                parameters[current.parameter.to_s] = section
              end
            else
              current = last[STAR_PLACEHOLDER]
              if current
                wildpath = '/' + parts[idx..-1].join('/')
                wildformat = File.extname(wildpath)
                unless wildformat.empty? || !current.extract_format
                  wildpath = wildpath[0..-(wildformat.length + 1)]
                  parameters['format'] = wildformat[1..-1].to_sym
                end
                parameters[current.parameter.to_s] = wildpath
                return [current.blk, parameters, current.opts, true]
              else
                return [nil, {}, nil]
              end
            end
          end
        end
        [nil, {}, nil]
      end

      # match a path to a route and call any associated block with the extracted parameters.
      def process(verb, path)
        blk, params = match(verb, path)
        blk&.call(params)
      end

      def routes
        hash = {}
        locations.values.each do |group|
          group.each do |route|
            verb = route[0]
            options = route[2]
            options_string = String.new
            options_string = ' ' + options.inspect.to_s unless options.empty?
            path = '/' + route[1]
            hash[path] ||= {}
            hash[path][verb] = options_string
          end
        end
        list = hash.to_a
        list.sort! { |a, b| a[0] <=> b[0] }
        str = String.new
        list.each do |route|
          pairs = route[1].to_a.sort{|a,b| a[0]<=>b[0]}
          pairs.each do |pair|
            str << pair[0] << "\t" << route[0] << "\t" << pair[1] << "\n"
          end
          str << "\n"
        end
        str
      end
    end

  end # RequestMapper

  class << self


    def set_path_root(*args)
      RequestMapper.set_path_root(*args)
    end

    def path_root
      RequestMapper.path_root
    end

    def full_path(path)
      RequestMapper.full_path(path)
    end

  end

  RequestMapper.set_path_root(ENV['BLIX_REST_ROOT']) if ENV['BLIX_REST_ROOT']
end # Rest
