module Blix
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