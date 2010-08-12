
#require 'sinatra' unless defined?(Sinatra)
include Mongo

Mindfli::Controller::configure do
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
