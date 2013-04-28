require 'grape'
require 'barmaid'

module Barmaid
  class API < Grape::API
    prefix '/api'
    format :json

    resource :recover_jobs do
      desc 'Return all recover jobs'
      get do
        statuses = RecoverJobStatuses.new(Resque::Plugins::Status::Hash.statuses)
        statuses.extend(Barmaid::Representers::RecoverJobStatusesRepresenter)
      end

      desc 'Create a new recover job'
      params do
        requires :server, :type => String, :desc => "Server id"
        requires :target, :type => String, :desc => "Target id"
        requires :backup_id, :type => String, :desc => "Backup id"
      end
      post do
        job_id = Barmaid::Job::RecoverJob.create(params)
        job_status = RecoverJobStatus.create(Resque::Plugins::Status::Hash.get(job_id))
        job_status.extend(Barmaid::Representers::RecoverJobStatusRepresenter)
      end

      desc 'Return a specific job'
      params do
        requires :id, :type => String, :desc => "Job id"
      end
      get ':id' do
        status = Resque::Plugins::Status::Hash.get(params[:id])
        error! "Job not found", 400 if status.nil?

        job_status = RecoverJobStatus.create(status)
        job_status.extend(Barmaid::Representers::RecoverJobStatusRepresenter)
      end

      desc 'Delete a backup'
      params do
        requires :id, :type => String, :desc => "Job id"
      end
      delete ':id' do
        status = Resque::Plugins::Status::Hash.get(params[:id])
        error! "Job not found", 400 if status.nil?

        if status.working?
          Resque::Plugins::Status::Hash.kill(params[:id])
        else
          Resque::Plugins::Status::Hash.remove(params[:id])
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
