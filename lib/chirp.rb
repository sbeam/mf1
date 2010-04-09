class Chirp

    def create(params)
      @id = DB['chirps'].save({'user' => params[:user], 
                              'text' => params[:text], 
                              'clicky'=>params[:url],
                              'created_at'=>Time.now.to_i})
    end

    def save_upload(fname, tmpfile)
        @grid = Grid.new(DB)
        file_id = @grid.put(tmpfile, fname, :safe => true)
        res = DB['chirps'].update({:_id=>@id}, {'$set'=>{:file=> file_id}}, {:multi=>true})
    end


    def self.latest(limit=50)
      DB['chirps'].find({}, {:sort=>[['created_at','descending']], :limit=>limit}).collect
    end


end
