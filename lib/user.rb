
class User

    def initialize(username)
        @current_user = DB['users'].find_one(:username => username)
    end
    
    def self.exists?(un)
        DB['users'].find(:username => un).count
    end

    # TODO don't use weak DES crypt
    def create(params)
      id = DB['users'].save({'username' => params[:username], 
                             'password' => params[:password].crypt((rand*100).to_s), 
                             'following' => [],
                             'created_at'=>Time.now.to_i})
      initialize(params[:username]) 
    end

    # creds = [username, pass]
    def check(creds)
        if @current_user.nil?
            create({:username => creds[0], :password => creds[1]})
        end
        creds[1].crypt(@current_user['password']) == @current_user['password']
    end

    def is_following?(username)
      if !@current_user.nil? && User.exists?(username)
        if followed_list = @current_user.to_a.assoc('following')
            followed_list[1].include?(username)
        end
      end
    end

    def who_follows
        @current_user['following']
    end

end
