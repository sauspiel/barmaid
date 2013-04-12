require 'grape'
require 'barmaid'

module Barmaid
  class API < Grape::API
    prefix '/api'
    format :json

    resource :recover_jobs do
      desc 'Return all recover jobs'
      get do
        result = Array.new
        Resque::Plugins::Status::Hash.statuses.each { |s| result << { :id => s.uuid } }
        result
      end

      desc 'Create a new recover job'
      params do
        requires :server, :type => String, :desc => "Server id"
        requires :target, :type => String, :desc => "Target id"
        requires :backup_id, :type => String, :desc => "Backup id"
      end
      post do
        job_id = Barmaid::Job::RecoverJob.create(params)
        {:id => job_id}
      end

      desc 'Return a specific job'
      params do
        requires :id, :type => String, :desc => "Job id"
      end
      get ':id' do
        status = Resque::Plugins::Status::Hash.get(params[:id])
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
        h
      end

      desc 'Delete a backup'
      params do
        requires :job_id, :type => String, :desc => "Job id"
      end
      delete ':job_id' do
        status = Resque::Plugins::Status::Hash.get(params[:job_id])
        error! "Job not found", 400

        if status.working?
          Resque::Plugins::Status::Hash.kill(params[:job_id])
        else
          Resque::Plugins::Status::Hash.remove(params[:job_id])
        end
        status 204
      end

    end

    resource :servers do
      desc 'Return all servers'
      get do
        servers = RBarman::Servers.all({ :with_backups => true })
        servers.add_targets
        servers.extend(Barmaid::Representers::ServersRepresenter)
      end

      desc 'Return a server'
      params do
        requires :id, :type => String, :desc => "Server id"
      end
      get ':id' do
        server = RBarman::Server.by_name(params[:id], { :with_backups => true })
        server.add_targets
        server.extend(Barmaid::Representers::ServerRepresenter)
      end

      desc "Return server's targets" 
      params do
        requires :server_id, :type => String, :desc => "Server id"
      end
      get ":server_id/targets" do
        server = RBarman::Server.by_name(params[:server_id])
        server.add_targets
        server.targets.extend(Barmaid::Representers::TargetsRepresenter)
      end

      desc "Return a target"
      params do
        requires :server_id, :type => String, :desc => "Server id"
        requires :id, :type => String, :desc => "Target id"
      end
      get ":server_id/targets/:id" do
        server = RBarman::Server.by_name(params[:server_id])
        server.add_targets
        target = server.targets.select { |t| t.id == params[:id] }.first
        raise "Implement me!" if target.nil?
        target.extend(Barmaid::Representers::TargetRepresenter)
      end

      desc "Return server's backups"
      params do
        requires :server_id, :type => String, :desc => "Server id"
      end
      get ":server_id/backups" do
        backups = RBarman::Backups.all(params[:server_id])
        backups.extend(Barmaid::Representers::BackupsRepresenter)
      end

      desc "Return a backup"
      params do
        requires :server_id, :type => String, :desc => "Server id"
        requires :id, :type => String, :desc => "Backup id"
      end
      get ":server_id/backups/:id" do
        backup = RBarman::Backup.by_id(params[:server_id], params[:id])
        backup.extend(Barmaid::Representers::BackupRepresenter)
      end
    end
  end
end
