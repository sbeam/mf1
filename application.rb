require 'rubygems'
require 'sinatra'
require 'environment'
require 'rack-flash'

enable :sessions
use Rack::Flash

configure do
  set :views, "#{File.dirname(__FILE__)}/views"
end

error do
  e = request.env['sinatra.error']
  Kernel.puts e.backtrace.join("\n")
  'Application error'
end


get '/' do
    ask_for_auth! # TODO poor little Safari needs this
    if @current_user.nil? or @current_user.who_follows.empty?
        @chirps = Chirp.latest(10)
    else
        @chirps = Chirp.latest(10, @current_user.who_follows << auth_username)
    end

    haml :root
end

get '/login' do
    protect!
    redirect '/'
end

get '/users/:username' do
    ask_for_auth!
    if User.exists?(params[:username])
        @chirps = DB['chirps'].find({:user => params[:username]},
                                    {:sort=>[['created_at','descending']]}).collect
        @user = DB['users'].find_one({:username => params[:username]})
    end
    haml :chirplist
end

post '/chirp' do
    protect!
    @chirp = Chirp.new
    @chirp.create(:text=>params[:chirp], :user=>auth_username, :url=>params[:url])

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


get '/follow/:username' do
    protect!
    if @user = DB['users'].find_one(:username => params[:username])
        DB['users'].update({:username => auth_username}, {'$addToSet' => {:following => params[:username]}});
        flash[:notice] = "You are now following '%s'" % params[:username]
    else
        flash[:error] = "You asked to follow someone that doesn't exist."
    end
    redirect '/'
end

post '/users/find' do
    @term = params[:term]
    @finded = DB['users'].find(:username => /#{params[:term]}/i)
    haml :searchresult
end

get '/profile' do
    protect!
    haml :profile
end

get '/reply/:chirp_id' do
    protect!
    @chirp = DB['chirps'].find_one(:_id => Mongo::ObjectID::from_string(params[:chirp_id]))
    if @chirp.nil? 
        flash['error'] = 'No such chirp!'
        redirect '/'
    end
    haml :reply
end

post '/reply/:chirp_id' do
    protect!
    @chirp = DB['chirps'].find_one(:_id => Mongo::ObjectID::from_string(params[:chirp_id]))
    if @chirp.nil? 
        flash['error'] = 'No such chirp!'
        redirect '/'
    end
    @chirp['replies'].push({:user => auth_username, :text => params[:chirp], :created_at => Time.now.to_i})
    DB['chirps'].save(@chirp)
    flash['notice'] = 'Reply accepted!'
    redirect '/'
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

  def protect!
    unless authorized?
      response['WWW-Authenticate'] = %(Basic realm="mf1 userlist")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  def ask_for_auth!  # this is here only for poor little Safari
      unless session[:did_auth].nil?
          protect!
      end
  end

  def authorized?
      authenticated? 
  end

  def authenticated?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    if @auth.provided? && @auth.basic? && @auth.credentials 
        @current_user = User.new(@auth.credentials[0])
        if @current_user && @current_user.check(@auth.credentials)
            session[:did_auth] = 1
        end
    end
  end

  def auth_username
      @auth.credentials[0] if authenticated?
  end

  def following? (username)
      if authenticated? && User.exists?(username)
          @current_user.is_following?(username)
      end
  end

end

