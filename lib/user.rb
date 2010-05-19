class User

    include MongoMapper::Document
    set_database_name DB_NAME

    plugin Joint

    key :username, String, {:required => true, :index => true}
    key :password, String
    key :active, Boolean
    key :following, Array
    key :openid_display_identifier, String
    key :openid_url, String, :index => true
    key :biography, String
    key :website, String
    timestamps!

    attachment :avatar
    attachment :background

    before_save :cryptpass


    # TODO don't use weak DES crypt
    def cryptpass
        !self.password.nil? && self.password = self.password.crypt((rand*100).to_s)
        self.active = true
    end
    
    def self.exists?(un)
        find_by_username(un)
    end

    # creds = [username, pass]
    def check(creds)
        creds[1].crypt(password) == password
    end

    def is_following?(username)
      if !@user_record.nil? && User.exists?(username)
        if followed_list = @user_record.to_a.assoc('following')
            followed_list[1].include?(username)
        end
      end
    end


end
