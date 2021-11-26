

module Blix

  def self.require_dir(path)
     raise "invalid dir path:#{path}" unless File.directory?(path)
     Dir.glob("#{path}/*.rb").each {|file| require File.expand_path(file)[0..-4] }
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
