

module Blix

  def self.require_dir(path)
     raise "invalid dir path:#{path}" unless File.directory?(path)
     Dir.glob("#{path}/*.rb").each {|file| require File.expand_path(file)[0..-4] }
  end

  def self.klass_to_name(klass)
     return unless klass
     klass = klass.to_s.split('::')[-1]
     klass.gsub(/([a-z]+)([A-Z]+)/){"#{$1}_#{$2}"}.downcase
   end

   def self.name_to_klass(name)
     construct_klass(name)
   end

   # construct a klass from a name
   def self.construct_klass(name)
     name && name.to_s.downcase.split('_').map(&:capitalize).join
   end

   def self.construct_singular(name)
     name && name.to_s.sub(/s$/,'')
   end

   def self.construct_plural(name)
     name && name.plural
   end

   def self.camelcase(str)
     downcase_front(construct_klass(str))
   end

   def self.downcase_front(str)
     str[0, 1].downcase + str[1..-1]
   end

   def self.underscore(str)
     str.gsub(/::/, '/')
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
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
