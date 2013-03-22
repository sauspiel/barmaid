require 'rspec'
require 'barmaid'

RSpec.configure do |config|
  config.color_enabled  = true
  config.formatter      = 'documentation'
  config.before(:each) do
    RBarman::CliCommand.any_instance.stub(:binary=)
    RBarman::CliCommand.any_instance.stub(:recover)
  end
end
