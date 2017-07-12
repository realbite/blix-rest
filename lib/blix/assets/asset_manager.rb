require 'digest'

module Blix
  # manage your asset names
  #
  # a config directory contains a file for each managed asset using its generic name. In the file
  # is the unique stamp that is used to find the name of the latest version of the asset.
  # config format consists of a filestamp part and md5 hash part
  #
  class AssetManager

    AssetInfo = Struct.new(:newname, :oldname)
    class << self
      def config_dir
        @config_dir || 'config/assets'
      end

      def config_dir=(val)
        @config_dir = val
      end

      # the name of the file to write to
      def filename(name)
        ext = File.extname(name)[1..-1]
        name.split('.')[0] + '.' + ext
      end

      # write the compiled asset here
      def dest_path(name)
        File.join(asset_dir,filename(name))
      end

      # write the config info here
      def config_path(name)
        File.join(config_dir,filename(name))
      end

      # yield the old and new name to a block if
      # the asset has been modified
      def if_modified(name,data,opts={})
        new_hash = Digest::MD5.hexdigest data

        ext = File.extname(name)[1..-1]
        base = name.split('.')[0]
        confname = base + '.' + ext
        config = get_config(confname)

        if !config || (config[:hash] != new_hash)
          stamp = get_filestamp

          info = AssetInfo.new
          info.newname = "#{base}-#{stamp}.#{ext}"
          info.oldname = config && "#{base}-#{config[:stamp]}.#{ext}"

          yield(info)

          set_config(confname,new_hash,stamp)

        elsif opts[:rewrite]   # rewrite the same date to the same asset as before

          info = AssetInfo.new
          info.newname = config && "#{base}-#{config[:stamp]}.#{ext}"
          info.oldname = nil
        yield(info)
        end
      end

      # generate a unique suffix for the file
      def get_filestamp
        now = Time.now
        str  = "%X" % now.to_i
        str += "%X" % now.usec
        str += "%X" % rand(9999)
        str
      end

      # get config data from file or nil if file does not exist
      def get_config(name)
        return nil unless File.exist? config_path(name)
        data = File.read config_path(name)
        parts=data.split('|')
        {:hash=>parts[1],:stamp=>parts[0]}
      end

      # set the config data
      def set_config(name,hash,stamp)
        File.write(config_path(name), stamp + '|' + hash)
        true
      end

      # cache asset name store
      def cache
        @cache ||= {}
      end

      # retrieve and cache the full asset name
      def get_asset_name(name)
        cache[name] ||= begin
          config = get_config(name)
          raise "ERROR : config file for asset:#{name} not found !!" unless config
          ext = File.extname(name)[1..-1]
          base = name.split('.')[0]
          base + '-' + config[:stamp] + '.' + ext
        end
      end

    end
  end

end