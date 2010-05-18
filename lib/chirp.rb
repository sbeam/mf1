class Chirp
    include MongoMapper::Document
    set_database_name DB_NAME

    plugin Joint

    key :text, String, :required => true
    key :clicky, String
    key :active, Boolean
    key :user, String

    key :replies, Array, :index => true
    #many :replies, :class_name => 'Chirp'

    timestamps!
    
    attachment :pic

    def add_reply(text, username)
        self.replies << {:user => username, :text => text, :created_at => Time.now}
        save
    end

    def self.latest(limit=50, userlist=[])
        if userlist.is_a?(Array) && userlist.count > 0
            all(:conditions => { :user => userlist }, :order => 'created_at desc', :limit => limit)
        else
            all(:order => 'created_at desc', :limit => limit)
        end
    end


end

