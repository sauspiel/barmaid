require './app.rb'
require './config/initializers/resque.rb'

run Barmaid::BarmaidApp.new
