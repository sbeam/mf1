require "#{File.dirname(__FILE__)}/spec_helper"

describe 'main application' do
  include Rack::Test::Methods

  def app
    @app ||= Mindfli::Controller
  end

  it 'should show the default index page' do
    get '/'
    last_response.should be_ok
  end

  it "should return 404 when page cannot be found" do
      get '/404'
      last_response.status.should == 404
  end

  it "should show the posting form on the home page" do
      get "/"
      last_response.body.contains "form"
  end

  it 'should have more specs' do
    pending
  end
end
