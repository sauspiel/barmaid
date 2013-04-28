require './lib/barmaid/api.rb'
require './config/initializers/resque.rb'
require './config/initializers/barmaid.rb'
require './config/initializers/jobs.rb'

run Barmaid::API.new
