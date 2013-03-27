dir = Barmaid::Config.config[:jobs]

unless dir.nil?
  Dir["#{dir}/*.rb"].each { |f| require f }
end
