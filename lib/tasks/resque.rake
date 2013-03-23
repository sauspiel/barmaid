require 'yaml'
require 'barmaid'
require 'resque/tasks'
require File.dirname(__FILE__) + '/../../config/initializers/resque.rb'
require File.dirname(__FILE__) + '/../../config/initializers/barmaid.rb'

namespace :resque do
  task :setup do
    ENV['QUEUE'] = 'recover_job_queue'
  end
end
