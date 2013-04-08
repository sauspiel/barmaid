require './app.rb'
require './config/initializers/resque.rb'
require './config/initializers/barmaid.rb'
require './config/initializers/jobs.rb'

require 'logger'
class ::Logger; alias_method :write, :<<; end
log = ::Logger.new("log/#{ENV['RACK_ENV']}.log")
use Rack::CommonLogger, log

run Barmaid::BarmaidApp.new
