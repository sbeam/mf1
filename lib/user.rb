class User

    include MongoMapper::Document
    set_database_name DB_NAME

    plugin Joint

    key :username, String, {:required => true, :index => true}
    key :password, String, :required => true
    key :active, Boolean
    key :following, Array
    key :openid_display_identifier, String
    key :openid_url, String, :index => true
    timestamps!

    attachment :avatar
    attachment :background

    before_save :cryptpass

    def create_from_openid(oid_response, reginfo)
        reginfo[:nickname] ||= oid_reponse.display_identifier

        create({:active => true, :username => reginfo[:nickname],
                :password => 'x', :openid_display_identifier => oid_reponse.display_identifier,
                :openid_url => oidresp.identity_url})
        save
    end

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

    def followers(un)
        find(:conditions => { :following => [un] })
    end

end
