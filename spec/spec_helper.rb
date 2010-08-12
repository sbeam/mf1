require File.join(File.dirname(__FILE__), '..', 'application.rb')

require 'rubygems'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'
require 'rack/test'
require 'sinatra'

# set test environment
Sinatra::Base.set :environment, :test
Sinatra::Base.set :run, false
Sinatra::Base.set :raise_errors, true
Sinatra::Base.set :logging, false

# establish in-memory database for testing
## TODO - MongoDB equiv - DataMapper.setup(:default, "sqlite3::memory:")

Spec::Runner.configure do |config|
  # reset database before each example is run
  ## TODO - MongoDB equiv - config.before(:each) { DataMapper.auto_migrate! }
end
