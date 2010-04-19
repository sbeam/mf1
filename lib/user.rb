
class User

    def initialize(username)
        @user_record = DB['users'].find_one(:username => username)
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

    def get(field)
        @user_record[field] if @user_record && @user_record[field]
    end

    def set(field, value)
        @user_record[field] = value
    end

    def save
        DB['users'].save(@user_record) if @user_record
    end

    def attach_file(key, filename, tmpfile)
        @grid = Grid.new(DB)
        file_id = @grid.put(tmpfile, filename, :safe => true)
        set(key, file_id)
    end

    # creds = [username, pass]
    def check(creds)
        if @user_record.nil?
            create({:username => creds[0], :password => creds[1]})
        end
        creds[1].crypt(@user_record['password']) == @user_record['password']
    end

    def is_following?(username)
      if !@user_record.nil? && User.exists?(username)
        if followed_list = @user_record.to_a.assoc('following')
            followed_list[1].include?(username)
        end
      end
    end

    def who_follows
        @user_record['following']
    end

    def followers(un)
        DB['users'].find(:following => un)
    end

end
