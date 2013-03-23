require './app.rb'
require './config/initializers/resque.rb'
require './config/initializers/barmaid.rb'

run Barmaid::BarmaidApp.new
