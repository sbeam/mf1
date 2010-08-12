require 'rubygems'
require 'haml'
require 'ostruct'
require 'mongo'
require 'mongo_mapper'
require 'rack-flash'
require 'joint'
#require 'sinatra-authentication'
gem 'ruby-openid', '>=2.1.7'
require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/sreg'
require 'openid/extensions/ax'
require 'rack/contrib'


require 'application'


FileUtils.mkdir_p 'log' unless File.exists?('log')
log = File.new("log/sinatra.log", "a+")
$stdout.reopen(log)
$stderr.reopen(log)

APP_ROOT = File.dirname(__FILE__)

use Rack::Profiler if ENV['RACK_ENV'] == 'development'
use Rack::ETag
#use Rack::MailExceptions

#run Sinatra::Application
run Mindfli::Controller
