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
      jsonp @config[:servers].keys
    end

    get '/api/servers/:server_id/targets' do
      jsonp @config[:servers][params[:server_id]][:targets].keys
    end

    get '/api/servers/:server_id/targets/:target_id' do
      jsonp @config[:servers][params[:server_id]][:targets][params[:target_id]]
    end

    get '/api/servers/:server_id/backups' do
      backups = RBarman::Backups.all(params[:server_id])
      jsonp backups.map { |b| b.id }
    end

    get '/api/servers/:server_id/backups/:backup_id' do
      b = RBarman::Backup.by_id(params[:server_id], params[:backup_id])
      h = Hash.new
      %w(size status backup_start backup_end timeline wal_file_size).each do |attr|
        h[attr] = b.send(attr.to_sym)
      end
      jsonp h
    end

    get '/api/recover_jobs' do
      jsonp 'implement me'
    end

    post '/api/recover_jobs' do
      halt(400) if params.empty?
      data = JSON.parse(request.body.read.to_s, :symbolize_names => true)
      opts = {:by_configuration => true}
      opts.merge!(data)
      jsonp Resque.enqueue(Barmaid::Job::RecoverJob, opts)
    end
  end
end
