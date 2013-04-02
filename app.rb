require 'json'
require 'sinatra/base'
require 'sinatra/reloader'
require 'sinatra/jsonp'
require 'barmaid'

module Barmaid
  class BarmaidApp < Sinatra::Base
    helpers Sinatra::Jsonp

    configure do 
      enable :logging
    end
    configure :test do
      set :raise_errors, true
      set :dump_errors, false
      set :show_exceptions, false 
    end

    configure :development do
      register Sinatra::Reloader
    end

    before do
      content_type 'application/json'
    end

    def initialize
      @config = Barmaid::Config.config
      super
    end

    get '/' do
      jsonp 'Barmaid, bring me some beer!'
    end

    get '/api' do
      jsonp 'Barmaid, bring me some beer!'
    end


    get '/api/servers' do
      a = Array.new
      @config[:servers].keys.each { |s| a << { :id => s } }
      jsonp a
    end

    get '/api/servers/:server_id/targets' do
      a = Array.new
      @config[:servers][params[:server_id].to_sym][:targets].keys.each { |k| a << { :id => k, :server_id => params[:server_id] } }
      jsonp a
    end

    get '/api/servers/:server_id/targets/:target_id' do
      h = Hash.new
      h.merge!(@config[:servers][params[:server_id].to_sym][:targets][params[:target_id].to_sym])
      h[:id] = params[:target_id]
      h[:server_id] = params[:server_id]
      jsonp h
    end

    get '/api/servers/:server_id/backups' do
      backups = RBarman::Backups.all(params[:server_id])
      a = Array.new
      backups.each { |b| a << { :id => b.id, :server_id => params[:server_id] } }
      jsonp a
    end

    get '/api/servers/:server_id/backups/:backup_id' do
      b = RBarman::Backup.by_id(params[:server_id], params[:backup_id])
      h = Hash.new
      %w(size status backup_start backup_end timeline wal_file_size).each do |attr|
        h[attr] = b.send(attr.to_sym)
      end
      h[:id] = b.id
      h[:server_id] = params[:server_id]
      jsonp h
    end

    get '/api/recover_jobs' do
      a = Array.new
      Resque::Plugins::Status::Hash.statuses.each { |s| a << { :id => s.uuid } }
      jsonp a
    end

    get '/api/recover_jobs/:job_id' do
      status = Resque::Plugins::Status::Hash.get(params[:job_id])
      h = Hash.new
      h[:status] = status.status
      h[:time] = status.time
      h[:message] = status.message || ""
      h[:pct_complete] = status.pct_complete
      h[:server] = status["options"]["server"]
      h[:target] = status["options"]["target"]
      h[:backup_id] = status["options"]["backup_id"]
      h[:completed_at] = status["completed_at"] || ""
      h[:id] = status.uuid
      jsonp h
    end

    delete '/api/recover_jobs/:job_id' do
      status = Resque::Plugins::Status::Hash.get(params[:job_id])
      if status.queued?
        jsonp Resque::Plugins::Status::Hash.remove(params[:job_id])
      elsif status.working?
        jsonp Resque::Plugins::Status::Hash.kill(params[:job_id])
      end
    end

    post '/api/recover_jobs' do
      halt(400) if params.empty?
      data = JSON.parse(request.body.read.to_s, :symbolize_names => true)
      job_id = Barmaid::Job::RecoverJob.create(data)
      jsonp({:id => job_id})
    end
  end
end
