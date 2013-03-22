require 'singleton'
require 'yaml'

module Barmaid
  class Configuration
    include Singleton

    def initialize
      settings
    end

    def settings
      if @settings.nil?
        @settings = YAML::load(File.open('config/barmaid.yml'))
      end
      return @settings
    end
  end
end
