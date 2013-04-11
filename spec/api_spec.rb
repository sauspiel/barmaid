require File.dirname(__FILE__) + "/../api.rb"
require 'rspec'
require 'rack/test'

include Barmaid

describe 'API' do
  include Rack::Test::Methods

  def app
    Barmaid::API
  end

  describe 'GET /api/servers' do
    it 'returns an array of all servers' do
      servers = RBarman::Servers.new
      servers << RBarman::Server.new("server1")
      servers << RBarman::Server.new("server2")
      RBarman::Servers.stub!(:all).and_return(servers)
      get '/api/servers'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result[0]["id"]).to eq('server1')
      expect(result[1]["id"]).to eq('server2')
    end
  end


end




