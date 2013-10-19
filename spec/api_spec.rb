require File.dirname(__FILE__) + "/../lib/barmaid/api.rb"
require 'rspec'
require 'rack/test'

include Barmaid

describe 'API' do
  include Rack::Test::Methods

  def app
    Barmaid::API
  end

  describe 'GET /api/servers' do
    it 'should return an array of all servers' do
      servers = RBarman::Servers.new
      servers << RBarman::Server.new("server1")
      servers << RBarman::Server.new("server2")
      RBarman::Servers.stub(:all).with({:with_backups => true}).and_return(servers)
      get '/api/servers'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result[0]["id"]).to eq('server1')
      expect(result[1]["id"]).to eq('server2')
    end
  end

  describe 'GET /api/servers/:id' do
    it 'should return a server' do
      server = RBarman::Server.new("server1")
      RBarman::Server.stub(:by_name).with('server1', {:with_backups => true}).and_return(server)
      get '/api/servers/server1'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      puts result
      expect(result["id"]).to eq('server1')
    end
  end

  describe 'GET /api/servers/:server_id/targets' do
    it 'should return an array of targets' do
      server = RBarman::Server.new("server1")
      targets = Array.new
      targets << Target.new("target1", "server1")
      targets << Target.new("target2", "server1")
      server.targets = targets
      RBarman::Server.stub(:by_name).with('server1').and_return(server)
      RBarman::Server.any_instance.stub(:add_targets)
      get '/api/servers/server1/targets'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result[0]["id"]).to eq('target1')
      expect(result[0]["server_id"]).to eq('server1')
      expect(result[1]["id"]).to eq('target2')
      expect(result[1]["server_id"]).to eq('server1')
    end
  end

  describe 'GET /api/servers/:server_id/targets/:id' do
    it 'should return a target' do
      server = RBarman::Server.new("server1")
      targets = Array.new
      targets << Target.new("target1", "server1")
      targets << Target.new("target2", "server1")
      server.targets = targets
      RBarman::Server.stub(:by_name).with('server1').and_return(server)
      RBarman::Server.any_instance.stub(:add_targets)
      get '/api/servers/server1/targets/target2'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result["id"]).to eq('target2')
      expect(result["server_id"]).to eq('server1')
    end
  end

  describe 'GET /api/servers/:server_id/backups' do
    it 'should return all backups' do
      backups = RBarman::Backups.new
      backups << RBarman::Backup.new.tap{|b| b.id = "20130304T080002"; b.server = "server1" }
      backups << RBarman::Backup.new.tap{|b| b.id = "20130304T080003"; b.server = "server1" }
      RBarman::Backups.stub(:all).and_return(backups)
      get '/api/servers/server1/backups'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result[0]["id"]).to eq('20130304T080002')
      expect(result[0]["server_id"]).to eq('server1')
      expect(result[1]["id"]).to eq('20130304T080003')
      expect(result[1]["server_id"]).to eq('server1')
    end
  end

  describe 'GET /api/servers/:server_id/backups/:backup_id' do
    it 'should return a backup' do
      backup = RBarman::Backup.new.tap{|b| b.id = "20130304T080002"; b.server = "server1" }
      RBarman::Backup.stub(:by_id).with('server1','20130304T080002').and_return(backup)
      get '/api/servers/server1/backups/20130304T080002'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result["id"]).to eq('20130304T080002')
      expect(result["server_id"]).to eq('server1')
    end
  end

  describe 'GET /api/recover_jobs' do
    it 'should return all recover jobs' do
      jobs = Array.new
      jobs << Resque::Plugins::Status::Hash.new.tap { |h| h.uuid = '1' }
      jobs << Resque::Plugins::Status::Hash.new.tap { |h| h.uuid = '2' }
      Resque::Plugins::Status::Hash.stub(:statuses).and_return(jobs)
      get '/api/recover_jobs'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result[0]["id"]).to eq('1')
      expect(result[1]["id"]).to eq('2')
    end
  end

  describe 'GET /api/recover_jobs/:id' do
    it 'should return a recover job' do
      job = Resque::Plugins::Status::Hash.new.tap { |h| h.uuid = '1' }
      job.options = {"server" => "server1", "target" => "target1", "backup_id" => "1" }
      Resque::Plugins::Status::Hash.stub(:get).with('1').and_return(job)
      get '/api/recover_jobs/1'
      expect(last_response).to be_ok
      result = JSON.parse(last_response.body)
      expect(result["id"]).to eq('1')
    end
  end

  describe 'POST /api/recover_jobs' do
    it 'should create a new recover job' do
      params = { :server => 'server1', :target => 'target1', :backup_id => '123' }
      Barmaid::Job::RecoverJob.stub(:create).and_return('2')
      job = Resque::Plugins::Status::Hash.new
      job.uuid = '2'
      job["options"] = params
      Resque::Plugins::Status::Hash.stub(:get).with('2').and_return(job)
      post '/api/recover_jobs', params
      expect(last_response.status).to eq(201)
      result = JSON.parse(last_response.body)
      expect(result["id"]).to eq('2')
    end
  end

end




