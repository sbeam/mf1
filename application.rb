require 'rubygems'
require 'sinatra'
require 'environment'
gem 'ruby-openid', '>=2.1.7'
require 'openid'
require 'openid/store/filesystem'


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
    if @current_user.nil? or @current_user.following.empty?
        @chirps = Chirp.latest(10)
    else
        @chirps = Chirp.latest(10, @current_user.following << auth_username)
    end

    haml :root
end

get '/login' do
    haml :login
end

post '/login' do
    openid_begin params[:openid_url]
    haml :login
end

get '/users/:username' do
    if User.exists?(params[:username])
        @chirps = Chirp.all(:conditions => {:user => params[:username]},
                            :order=>'created_at desc')
        @user = DB['users'].find_one({:username => params[:username]})
    end
    haml :chirplist
end

post '/login/openid' do
    openid = params[:openid_url]
    begin
      oidreq = openid_consumer.begin(openid)
    rescue OpenID::DiscoveryFailure => why
      "Sorry, we couldn't find your identifier '#{openid}'"
    else
      # You could request additional information here - see specs:
      # http://openid.net/specs/openid-simple-registration-extension-1_0.html
      #oidreq.add_extension_arg('sreg','required','email')
      # oidreq.add_extension_arg('sreg','optional','fullname, email')
       
       
      add_simple_registration_fields(oidreq, { :required => 'email', :optional => ['nickname','dob'] })
       
      # Send request - first parameter: Trusted Site,
      # second parameter: redirect target
      redirect oidreq.redirect_url(root_url, root_url + "/login/openid/complete")
    end
end


get '/login/openid/complete' do
    oidresp = openid_consumer.complete(params, request.url)

    case oidresp.status
    when OpenID::Consumer::FAILURE
        flash[:error] = "Sorry, we could not authenticate you with the given identifier"
        redirect '/login'

    when OpenID::Consumer::SETUP_NEEDED
        flash[:error] = "Immediate request failed - Setup Needed"
        redirect '/login'

    when OpenID::Consumer::CANCEL
        flash[:error] = "Login cancelled."
        redirect '/login'

    when OpenID::Consumer::SUCCESS
        # Access additional informations:
        # puts params['openid.sreg.nickname']
        # puts params['openid.sreg.fullname']

        # Startup something
        # Maybe something like
        session[:openid_display_identifier] = oidresp.display_identifier
        session[:openid_nick] = params['openid.sreg.nickname']


        if is_google_federated_login?(oidresp)
            registration = OpenID::AX::FetchResponse.from_success_response(oidresp)
        else
            registration = OpenID::SReg::Response.from_success_response(oidresp)
        end


        if registration.class.to_s == "OpenID::AX::FetchResponse"
          email = registration['http://schema.openid.net/contact/email']
        else
          email = registration['email']
        end
        

        @reg = registration

        email

        #flash[:notice] = "OpenID login successful."
        #redirect '/'
    end
end




post '/chirp' do
    protect!
    if (params[:url])
        if (! validate_url(params[:url]) )
            flash[:error] = "That doesn't look like a proper link!"
            redirect '/'
        end
    end
    if "http://".eql?(params[:url].downcase)
        params[:url] = nil
    end
    @chirp = Chirp.create(:text=>params[:chirp], :user=>auth_username, :url=>params[:url])

    if params[:pic] && (tmpfile = params[:pic][:tempfile])
        @chirp.pic = params[:pic][:tempfile]
    end

    if @chirp.save!
        flash[:notice] = "Accepted."
    end
    
    redirect '/'
end

get '/images/:grid_id' do
    @grid = Grid.new(DB)
    if img = @grid.get(BSON::ObjectID::from_string(params[:grid_id]))
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
    @profile = User.new(auth_username)
    haml :profile
end

post '/profile' do
    protect!
    @profile = User.new(auth_username)
    @profile.set('biography', params[:biog])
    @profile.set('website', params[:url])

    [:pic, :background].each do |file|
        if params[file] && (tmpfile = params[file][:tempfile]) && (name = params[file][:filename])
            @profile.attach_file(file, name, tmpfile)
        end
    end

    if @profile.save
        flash[:notice] = "Your new profile is saved!"
    end

    redirect '/profile'
end

get '/reply/:chirp_id' do
    protect!
    @chirp = Chirp.find_by_id(params[:chirp_id])
    if @chirp.nil? 
        flash['error'] = 'No such chirp!'
        redirect '/'
    end
    @chirps = [ @chirp ]
    haml :reply
end

post '/reply/:chirp_id' do
    protect!
    @chirp = Chirp.find_by_id(params[:chirp_id])
    if @chirp.nil? 
        flash['error'] = 'No such chirp!'
        redirect '/'
    end
    if @chirp.add_reply(params[:chirp], auth_username)
        flash['notice'] = 'Reply accepted!'
    end
    redirect '/'
end

helpers do

    def openid_consumer
        @openid_consumer ||= OpenID::Consumer.new(session,
                                                  OpenID::Store::Filesystem.new("#{APP_ROOT}/tmp/openid"))
    end
    

    def protect!
        unless authenticated?
            #session[:pre_auth_action] = request.method
            redirect '/login'
        end
    end

    def openid_begin (url)
        response = openid_consumer.begin url

        if response.status == OpenID::SUCCESS
            redirect_url = response.redirect_url(home_url, complete_openid_url)
            redirect redirect_url
            return
        end
    end


    def authenticated?
        false
    end

  def auth_username
      @auth.credentials[0] if authenticated?
  end

  def following? (username)
      if authenticated? && User.exists?(username)
          @current_user.is_following?(username)
      end
  end

  def get_user_bg(username)
      unless username.nil?
          username = username['username'] unless username.is_a? String
          if User.exists?(username)
              user = User.find_by_username(username)
              id = user.background_id
              unless id.nil?
                  return "/images/%s" % id.to_s 
              end
          end
      end
      '/waxwings.jpg'
  end

  def root_url
      request.url.match(/(^.*\/{2}[^\/]*)/)[1]
  end

  # Usage: partial :foo
  def partial(page, options={})
    haml page, options.merge!(:layout => false)
  end

  def time_ago_in_words(timestamp)
      timestamp = timestamp.to_i if timestamp.is_a? Time

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

  def validate_url(url)
      return url.match(URL_REGEXP)
  end

  def add_simple_registration_fields(open_id_request, fields)
      if is_google_federated_login?(open_id_request)
          ax_request = OpenID::AX::FetchRequest.new
          # Only the email attribute is currently supported by google federated login
          email_attr = OpenID::AX::AttrInfo.new('http://schema.openid.net/contact/email', 'email', true)
          ax_request.add(email_attr)
          open_id_request.add_extension(ax_request)
      else
          sreg_request = OpenID::SReg::Request.new
          sreg_request.request_fields(Array(fields[:required]).map(&:to_s), true) if fields[:required]
          sreg_request.request_fields(Array(fields[:optional]).map(&:to_s), false) if fields[:optional]
          sreg_request.policy_url = fields[:policy_url] if fields[:policy_url]

          open_id_request.add_extension(sreg_request)
      end
  end

  def is_google_federated_login?(request_response)
      return request_response.endpoint.server_url == "https://www.google.com/accounts/o8/ud"
  end
  
  

end

URL_REGEXP = Regexp.new('\b ((https?|telnet|gopher|file|wais|ftp) : [\w/#~:.?+=&%@!\-] +?) (?=[.:?\-] * (?: [^\w/#~:.?+=&%@!\-]| $ ))', Regexp::EXTENDED)
AT_REGEXP = Regexp.new('\s@[\w.@_-]+', Regexp::EXTENDED)
  
