class Chirp
    include MongoMapper::Document
    set_database_name DB_NAME

    key :text, String, :required => true
    key :clicky, String
    #key :created_at, Time, :required => true
    key :active, Boolean
    timestamps!
    

    #before_create :set_time  

    def save_upload(fname, tmpfile)
        @grid = Grid.new(DB)
        file_id = @grid.put(tmpfile, { :filename => fname, :safe => true } )
        res = DB['chirps'].update({:_id=>@id}, {'$set'=>{:file=> file_id}}, {:multi=>true})
    end


    def self.latest(limit=50, userlist=[])
        conditions = {}
        if userlist.count > 0
            conditions = {:user => {:$in => userlist}}
        end
        DB['chirps'].find(conditions, {:sort=>[['created_at','descending']], :limit=>limit}).collect
    end
    private  


    def set_time   
        self[:created_at] = Time.now.to_i
    end 

end

