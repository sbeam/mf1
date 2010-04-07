require 'rubygems'
require 'haml'
require 'ostruct'
require 'mongo'

require 'sinatra' unless defined?(Sinatra)
include Mongo

configure do
  SiteConfig = OpenStruct.new(
                 :title => 'mindf.li',
                 :author => 'Sam Beam',
                 :url_base => 'http://localhost:4567/'
               )

  #DataMapper.setup(:default, "sqlite3:///#{File.expand_path(File.dirname(__FILE__))}/#{Sinatra::Base.environment}.db")

  DB = Connection.new(ENV['DATABASE_URL'] || 'localhost').db('mindfli')

  if ENV['DATABASE_USER'] && ENV['DATABASE_PASSWORD']
      auth = DB.authenticate(ENV['DATABASE_USER'], ENV['DATABASE_PASSWORD'])
  end

  # load models
  $LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")
  Dir.glob("#{File.dirname(__FILE__)}/lib/*.rb") { |lib| require File.basename(lib, '.*') }
end
