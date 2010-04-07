require 'rubygems'
require 'sinatra'
require 'environment'


configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  'Application error'
end

helpers do
  # add your helpers here
end

get '/' do
    @chirps = Chirp.latest(10)
    haml :root
end

get '/new' do
    haml :new_post
end

get '/story/:story_id' do
end

post '/new' do
    @chirp = Chirp.create(:text=>params[:chirp], :user=>'sbeam', :url=>params[:url])
    redirect '/'
end
