require 'rubygems'
require 'haml'
require 'ostruct'
require 'mongo'
require 'mongo_mapper'
require 'rack-flash'
require 'joint'

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
end
