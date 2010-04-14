require 'rubygems'
require 'sinatra'
require 'environment'

enable :sessions

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
    if session[:flash] 
        @flash = session[:flash]
    end

    haml :root
end

get '/new' do
    haml :new_post
end

get '/chirp/:chirp_id' do
end

post '/new' do
    @chirp = Chirp.new
    @chirp.create(:text=>params[:chirp], :user=>session[:open_id], :url=>params[:url])

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

  def time_ago_in_words(timestamp)
      minutes = (((Time.now.to_i - timestamp).abs)/60).round
      return nil if minutes < 0

      case minutes
      when 0 then 'less than a minute ago'
      when 0..4 then 'less than 5 minutes ago'
      when 5..49 then minutes.to_s + ' minutes ago'
      when 50..70 then 'about 1 hour ago'
      when 70..119 then 'over 1 hour ago'
      when 120..239 then 'more than 2 hours ago'
      when 240..1440 then 'about '+(minutes/60).round.to_s+' hours ago'
      else Time.at(timestamp).strftime('%I:%M %p %d-%b-%Y')
      end
  end

end

