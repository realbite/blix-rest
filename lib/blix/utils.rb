require 'yaml'

module Blix

  def self.require_dir(path)
     raise "invalid dir path:#{path}" unless File.directory?(path)
     Dir.glob("#{path}/*.rb").each {|file| require File.expand_path(file)[0..-4] }
  end

  # read a configuration hash from a yaml file depending on the current environment
  # and using a user specified file or default locations.
  class YamlConfig

    HOME_DIR = ENV['HOME'] || Dir.pwd
    DEFAULT_FILE_NAME = "blix"
    DEFAULT_CONFIG_DIR = "config"

    class ConfigError < StandardError; end

    # create a new configuration object
    def initialize(*args)

      if args.length > 2
        raise ConfigError, "too many arguments"
      elsif args.length > 1
        opts = args[1]
        env = args[0]
      elsif args.length > 0
        if args[0].kind_of? Hash
          opts = args[0]
          if defined? Blix::Rest.environment
             env = Blix::Rest.environment
          else
            env = ENV['RACK_ENV']
          end
        else
          opts = {}
          env = args[0]
        end
      else
        opts = {}
        env = Blix::Rest.environment
      end

      raise ConfigError, "environment required!" unless env

      file_name = opts["name"] || opts[:name] || DEFAULT_FILE_NAME
      file_name = file_name + ".yml" unless file_name[-4,4] == ".yml"

      # look for a file
      if config_file = opts["file"] || opts[:file]
        unless File.exist?(config_file)
          raise ConfigError, "blix config file:#{config_file} not found"
        end
      elsif File.exist?("#{HOME_DIR}/.#{file_name}")
         config_file = "#{HOME_DIR}/.#{file_name}"
      elsif File.exist?("#{DEFAULT_CONFIG_DIR}/#{file_name}")
        config_file = "#{DEFAULT_CONFIG_DIR}/#{file_name}"
      else
        raise ConfigError, "no blix config file found - pass as :file / :name  parameter or default config/blix.yml or ~.blix.yml"
      end

      yaml = YAML.load File.read( config_file)
      @config = yaml && yaml[env.to_s]

      raise ConfigError, "cannot read yaml configuration data from #{config_file} for environment:#{env} " unless @config

      @config
    end

    def [](k)
      @config[k.to_s]
    end

  end




  # filter the hash using the supplied filter
  #
  # the filter is an array of keys that are permitted
  # returns a hash containing only the permitted keys and values
  def self.filter_hash(filter,hash)
    hash = hash || {}
    hash.select {|key, value| filter.include?(key.to_sym) ||  filter.include?(key.to_s)}
  end

  # used to raise errors on
  module DatamapperExceptions
    def save(*args)
      raise ServiceError, errors.full_messages.join(',') unless super
      self
    end

    def update(*args)
      raise ServiceError, errors.full_messages.join(',') unless super
      self
    end

    def destroy(*args)
      raise ServiceError, errors.full_messages.join(',') unless super
      true
    end

    module ClassMethods

    end

    def self.included(mod)
      mod.extend DatamapperExceptions::ClassMethods
    end

  end

end

class String

  # try to convert utf special characters to normal characters.
  def to_ascii
    unicode_normalize(:nfd).gsub(/[\u0300-\u036f]/, "")
  end

  # standardize utf strings
  def normalize
    unicode_normalize(:nfc)
  end

end
