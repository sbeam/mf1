require '../application'
require 'testhelper'
require 'test/unit'
require 'rack/test'

Test::Unit::TestCase.send :include, Rack::Test::Methods

class SinatraMF1Test < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Mindfli
  end

  def setup
    post '/signup', TestHelper.gen_user
    follow_redirect!
    get '/logout'
  end

end

