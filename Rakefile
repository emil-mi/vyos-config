require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:test) do |t|
  t.pattern = 'spec/unit/**/*_spec.rb'
end

task :default => :test