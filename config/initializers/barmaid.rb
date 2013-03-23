require 'yaml'

env = ENV['RACK_ENV'] || 'development'
Barmaid::Config.config = YAML.load_file(File.dirname(__FILE__) + '/../barmaid.yml')
