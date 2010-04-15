class User
    
    # TODO don't use weak DES crypt
    def self.create(params)
      id = DB['users'].save({'username' => params[:username], 
                             'password' => params[:password].crypt((rand*100).to_s), 
                             'created_at'=>Time.now.to_i})
      @current_user = DB['users'].find_one(id)
    end

    # creds = [username, pass]
    def self.check(creds)
        @current_user ||= DB['users'].find_one('username' => creds[0])
        if @current_user.nil?
            self.create({:username => creds[0], :password => creds[1]})
        end
        creds[1].crypt(@current_user['password']) == @current_user['password']
    end

    def self.exists?(un)
        DB['users'].find(:username => un).count
    end


end
