require 'rubygems'
require 'sinatra'
require 'environment'
require 'openid'
require 'openid/store/filesystem'
require 'openid/extensions/sreg'

OPENID_REALM = 'http://localhost:9393'
OPENID_RETURN_TO = "#{OPENID_REALM}/login/openid/complete"

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

    if !session[:open_id]
        redirect '/login'
        return
    end

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

get '/login' do
    haml :login
end

post '/login' do
    session = nil
    begin
      oidreq = openid_consumer.begin params[:openid_url]
    rescue OpenID::DiscoveryFailure => why
      @error = "Sorry, we couldn't find your identifier '#{params[:openid_url]}'"
      haml :login
    else
        sregreq = OpenID::SReg::Request.new
        sregreq.request_fields(['email','nickname'], true)
        sregreq.request_fields(['dob', 'fullname'], false)
        oidreq.add_extension(sregreq)
        if oidreq.send_redirect?(OPENID_REALM, OPENID_RETURN_TO)
            redirect oidreq.redirect_url(OPENID_REALM, OPENID_RETURN_TO)
        end
        oidreq.html_markup(OPENID_REALM, OPENID_RETURN_TO)
    end
end

get '/login/openid/complete' do
  oidresp = openid_consumer.complete(params, OPENID_RETURN_TO)
  if oidresp.status == OpenID::Consumer::SUCCESS
      sreg_resp = OpenID::SReg::Response.from_success_response(oidresp)
      sreg_message = "Simple Registration data was requested"
      if sreg_resp.empty?
          sreg_message << ", but none was returned."
      else
          sreg_message << ". The following data were sent:"
          sreg_resp.data.each {|k,v|
              sreg_message << "<br/><b>#{k}</b>: #{v}"
          }
      end
      session[:flash] = @sreg_message
      session[:open_id] = [:url => oidresp.identity_url,
                          :nick => params['openid.sreg.nickname'],
                          :name => params['openid.sreg.fullname']]
      sreg_message
      #redirect '/'
  else
      session[:open_id] = nil
      'Could not log on with your OpenID'
  end
end

get '/logout' do
    session[:open_id] = nil
    redirect '/'
end

helpers do

    def logged_in?
        !session[:open_id].nil?
    end

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

