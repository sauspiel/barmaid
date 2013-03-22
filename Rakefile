require "bundler/gem_tasks"
require "rspec/core/rake_task"
Dir.glob('lib/tasks/*.rake').each { |r| import r}

RSpec::Core::RakeTask.new('spec')

task :default => :spec

desc "Creating ctags"
task :ctags do
  sh('ctags -R --exclude=.git .')
end
