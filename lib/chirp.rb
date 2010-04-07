class Chirp

    def self.create(params)
      DB['users'].insert({'user' => params[:user], 
                          'text' => params[:text], 
                          'clicky'=>params[:url]})
    end

    def self.latest(limit=50)
      DB['users'].find({'user'=>'sbeam'}).collect
    end


end

