source "https://rubygems.org"

gem 'mocha', :require => false
gem 'puppet',       '3.0.1'
gem 'facter',       '1.6.16'
gem 'rspec-puppet', '0.1.5'
gem 'rake',         '10.0.2'
gem 'cucumber',     '1.2.1'
gem 'puppetlabs_spec_helper', '0.3.0'
gem 'require_relative' if RUBY_VERSION =~ /1\.8/

#for windows only
if RUBY_PLATFORM.include? 'mingw32'
  gem 'sys-admin'
  gem 'win32-process'
  gem 'win32-dir'
  gem 'win32-service'
  gem 'win32-taskscheduler'
end