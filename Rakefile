require "bundler/gem_tasks"
Dir.glob('lib/tasks/*.rake').each { |r| import r}

begin 
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new('spec')
  task :default => :spec
rescue LoadError
end

desc "Creating ctags"
task :ctags do
  sh('ctags -R --exclude=.git .')
end
