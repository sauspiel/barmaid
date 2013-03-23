require 'barmaid'
require 'yaml'
require 'resque/tasks'
require File.dirname(__FILE__) + '/../../config/initializers/resque.rb'

namespace :resque do
  task :setup do
    ENV['QUEUE'] = 'recover_job_queue'
  end
end
