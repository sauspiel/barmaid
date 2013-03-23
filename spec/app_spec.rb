require File.dirname(__FILE__) + "/../app.rb"
require 'rspec'
require 'rack/test'

include Barmaid

describe 'BarmaidApp' do
  include Rack::Test::Methods

  def app
    BarmaidApp
  end

  it 'calls /api/recover_jobs and shoult return 400 when no parameters given' do
    post '/api/recover_jobs'
    expect(last_response.status).to eq(400)
  end

  it "calls /api/recover_jobs" do
    post '/api/recover_jobs', {"server" => "sauspiel", "target" => "123"}.to_json
    expect(last_response).to be_ok
  end


end




