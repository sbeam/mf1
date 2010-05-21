require 'rubygems'
require 'sinatra/base'
require 'haml'
require 'sinatra-authentication'
require 'ostruct'
require 'mongo'
require 'mongo_mapper'
require 'rack-flash'
require 'joint'
gem 'ruby-openid', '>=2.1.7'
require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/sreg'
require 'openid/extensions/ax'

require 'sinatra' unless defined?(Sinatra)
include Mongo

configure do
  SiteConfig = OpenStruct.new(
                 :title => 'mindf.li',
                 :author => 'Sam Beam',
                 :url_base => 'http://localhost:4567/'
               )
  DB_NAME = 'mindfli'

  # here is the mongodb driver connection
  DB = Connection.new(ENV['DATABASE_URL'] || 'localhost').db(DB_NAME)

  if ENV['DATABASE_USER'] && ENV['DATABASE_PASSWORD']
      auth = DB.authenticate(ENV['DATABASE_USER'], ENV['DATABASE_PASSWORD'])
  end

  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }

  APP_ROOT = File.dirname(__FILE__)

end

logger = Logger.new($stdout)
