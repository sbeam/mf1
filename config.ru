require 'application'
require 'sinatra'
#require 'rack/contrib'

set :run, false
set :environment, :development
set :raise_errors, true

FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

APP_ROOT = File.dirname(__FILE__)

#
#
#


use Rack::Profiler if ENV['RACK_ENV'] == 'development'

use Rack::ETag
#use Rack::MailExceptions

run Sinatra::Application
