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

get '/' do
    @chirps = Chirp.latest(10)
    haml :root
end

get '/new' do
    haml :new_post
end

get '/chirp/:chirp_id' do
end

post '/new' do
    @chirp = Chirp.new
    @chirp.create(:text=>params[:chirp], :user=>'sbeam', :url=>params[:url])

    if params[:pic] && (tmpfile = params[:pic][:tempfile]) && (name = params[:pic][:filename])
        @chirp.save_upload(name, tmpfile)
    end
    
    redirect '/'
end


get '/images/:grid_id' do
    @grid = Grid.new(DB)
    if img = @grid.get(Mongo::ObjectID::from_string(params[:grid_id]))
        headers 'Content-Type' => img.content_type,
                'Last-Modified' => img.upload_date.httpdate,
                'X-UA-Compatible' => 'IE=edge'
        
        img.read
    end
end


helpers do

  # Usage: partial :foo
  def partial(page, options={})
    haml page, options.merge!(:layout => false)
  end

end

