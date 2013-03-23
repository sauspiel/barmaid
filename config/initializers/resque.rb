require 'resque'
require 'yaml'

env = ENV['RACK_ENV'] || 'development'
config = YAML.load_file(File.dirname(__FILE__) + '/../resque.yml')
Resque.redis = config[env]

