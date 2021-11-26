# frozen_string_literal: true
require 'yaml'

module Blix
  # read a configuration hash from a yaml file depending on the current environment
  # and using a user specified file or default locations.
  #
  # options:
  #   :name     # the config file name
  #   :file     # the fixed file name

  class YamlConfig

    HOME_DIR = ENV['HOME'] || Dir.pwd
    DEFAULT_FILE_NAME = 'blix'
    DEFAULT_CONFIG_DIR = 'config'

    class ConfigError < StandardError; end

    # create a new configuration object
    def initialize(*args)
      if args.length > 2
        raise ConfigError, 'too many arguments'
      elsif args.length > 1
        opts = args[1]
        env = args[0]
      elsif !args.empty?
        if args[0].is_a? Hash
          opts = args[0]
          env = if defined? Blix::Rest.environment
                  Blix::Rest.environment
                else
                  ENV['RACK_ENV']
                end
        else
          opts = {}
          env = args[0]
        end
      else
        opts = {}
        env = Blix::Rest.environment
      end

      raise ConfigError, 'environment required!' unless env

      file_name = opts['name'] || opts[:name] || DEFAULT_FILE_NAME
      file_name = file_name.to_s
      file_name += '.yml' unless file_name[-4, 4] == '.yml'

      # look for a file
      if config_file = opts['file'] || opts[:file]
        config_file = config_file.to_s
        unless File.exist?(config_file)
          raise ConfigError, "blix config file:#{config_file} not found"
        end
      elsif File.exist?("#{HOME_DIR}/.#{file_name}")
        config_file = "#{HOME_DIR}/.#{file_name}"
      elsif File.exist?("#{DEFAULT_CONFIG_DIR}/#{file_name}")
        config_file = "#{DEFAULT_CONFIG_DIR}/#{file_name}"
      else
        raise ConfigError, 'no blix config file found - pass as :file / :name  parameter or default config/blix.yml or ~.blix.yml'
      end

      yaml = YAML.safe_load File.read(config_file)
      raise ConfigError, "cannot read yaml configuration data from #{config_file} for environment:#{env} " unless yaml && yaml.key?(env.to_s)
      @config = yaml[env.to_s] || {}
    end

    def [](k)
      @config[k.to_s]
    end

  end
end
