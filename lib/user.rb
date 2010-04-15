class User
    
    def self.exists?(un)
        DB['users'].find(:username => un).count
    end

    # TODO don't use weak DES crypt
    def self.create(params)
      id = DB['users'].save({'username' => params[:username], 
                             'password' => params[:password].crypt((rand*100).to_s), 
                             'created_at'=>Time.now.to_i})
      @current_user = User.new(params[:username]) #@current_user = DB['users'].find_one(id)
    end

    def initialize(username)
        @current_user = DB['users'].find_one(:username => username)
    end

    # creds = [username, pass]
    def check(creds)
        if @current_user.nil?
            User.create({:username => creds[0], :password => creds[1]})
        end
        creds[1].crypt(@current_user['password']) == @current_user['password']
    end

    def following?(user)
      if User.exists?(username)
        followed_list = @current_user.to_a.assoc('following').pop
        followed_list.include?(username)
      end
    end


end
