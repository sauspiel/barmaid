require 'barmaid'
require 'resque/tasks'

task "resque:setup" do
  ENV['QUEUE'] = 'recover_job_queue'
end
