module Barmaid
  module Config
    def self.config
      @@config ||= {}
    end

    def self.config=(hash)
      @@config = hash
    end
  end
end
