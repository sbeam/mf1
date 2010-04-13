require 'rubygems'
require 'sinatra'
require 'environment'
require 'openid'
require 'openid/store/filesystem'

OPENID_REALM = 'http://localhost:9393'
OPENID_RETURN_TO = "#{OPENID_REALM}/complete"

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

get '/login' do
    haml :login
end

post '/login' do
    begin
      response = openid_consumer.begin params[:openid_url]
      redirect response.redirect_url(OPENID_REALM, OPENID_RETURN_TO) if response.send_redirect?(OPENID_REALM, OPENID_RETURN_TO)
      response.html_markup(OPENID_REALM, OPENID_RETURN_TO)
    rescue
        @error = "Couldn't find an OpenID for that URL"
        haml :login
    end
end

get '/complete' do
  response = openid_consumer.complete(params, OPENID_RETURN_TO)
  if response.status == OpenID::Consumer::SUCCESS
      session[:open_id_identity] = response.identity_url
      redirect '/'
  else
      'Could not log on with your OpenID'
  end
end


helpers do


    def openid_consumer
        if @openid_consumer.nil?
            @openid_consumer = OpenID::Consumer.new(session, OpenID::Store::Filesystem.new('auth/store')) 
        end
        return @openid_consumer
    end


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

