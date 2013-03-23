require 'mixlib/shellout'

module Barmaid
  module Job
    class RecoverJob
      include ::Resque::Plugins::UniqueJob

      @queue = 'recover_job_queue'

      # @return [RBarman::Backup] the backup which should be recoverd
      # @see http://rubydoc.info/gems/rbarman/RBarman/Backup RBarman::Backup
      attr_accessor :backup

      # @return [Hash] options passed to the recovering process
      # @see http://rubydoc.info/gems/rbarman/RBarman/Backup:recover RBarman::Backup#recover
      attr_accessor :recover_opts

      # @return [String] the path to which the backup should be recovered.
      # @note If {#recover_opts} contains :remote_ssh_cmd, the path is remote, otherwise local
      attr_accessor :path
      
      # initializes a new instance of RecoverJob
      # @param [RBarman::Backup] backup the backup which should be recovered (see {http://rubydoc.info/gems/rbarman/RBarman/Backup RBarman::Backup})
      # @param [String] path the path to which the backup should be recovered (see {#path})
      # @param [Hash] recover_opts options passed to the recovering process (see {http://rubydoc.info/gems/rbarman/RBarman/Backup:recover RBarman::Backup#recover})
      def initialize(backup, path, recover_opts = {})
        @backup = backup
        @recover_opts = recover_opts
        @path = path
        @log = Logger.log('RecoverJob')
      end

      # factory method for creating a new {RecoverJob}. Calls barman cmd to retrieve backup information (including wal files) and {#perform!}
      # @param [Hash] params the parameters for creating a new {RecoverJob}
      # @option params [String] :server the server which contains the backup
      # @option params [String] :backup_id the id of the backup (like '20130321T045638')
      # @option params [String] :path the path to which the backup should be recovered (see {#path})
      # @option params [Boolean] :by_configuration if settings should be loaded from configuration (see {RecoverJob.create_job_by_configuration})
      # @option params [Hash] :recover_opts options passed to the recovering process (see {http://rubydoc.info/gems/rbarman/RBarman/Backup:recover RBarman::Backup#recover})
      # @option params [Hash] :job_opts job specific options (see {#perform!})
      # @return [void]
      def self.perform(params)
        sym_params = params.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        backup = RBarman::Backup.by_id(sym_params[:server], sym_params[:backup_id], {:with_wal_files => true})
        raise "No backup with id #{sym_params[:backup_id]} for server #{sym_params[:server]} found!" if backup.nil?

        job = nil
        begin
          if !sym_params[:by_configuration]
            job = RecoverJob.new(backup, sym_params[:path], sym_params[:recover_opts] || {})
          else
            job = RecoverJob.create_job_by_configuration(sym_params, backup)
          end
          job.perform!(sym_params[:job_opts] || {})
        rescue => e
          Logger.log('RecoverJob').error(e.message)
          Logger.log('RecoverJob').error(e.backtrace.join("\n"))
          raise e
        end
      end

      # creates a RecoverJob or a subclass of it
      # @param [Hash] params the parameters for creating a new {RecoverJob} (see {RecoverJob.perform})
      # @param [RBarman::Backup] backup the backup which should be recovered
      # @raise [RuntimeError] if no server configuration according to params[:server] could be found
      # @raise [RuntimeError] if params do not contain a :target definition
      # @raise [RuntimeError] if :target is not configured for server
      # @raise [RuntimeError] if no target configuration according to params[:target] could be found
      # @raise [RuntimeError] if no path configuration could be found
      # @return [RecoverJob]
      # @note this method requires that params contains a :target with a string value to identify the required target settings from the configuration. Also params[:recover_opts][:remote_ssh_cmd] and params[:recover_opts][:path], if given, will be overwritten by the according settings from configuration. If the configuration contains a "recover_job_name" setting, this method tries to instantiate an object with that name and returns that, otherwise an instance of RecoverJob will be returned
      def self.create_job_by_configuration(params, backup)
        raise "params must not be nil!" if params.nil?

        raise "params does not contain a :target definition" if params[:target].nil?

        config = Barmaid::Config.config[:servers]
        raise "No :servers configuration found! Please check your barmaid configuration!" if config.nil?

        raise "Could not find a configuration for server #{params[:server]}" if config[params[:server].to_sym].nil?

        raise "No targets defined for server #{params[:servers]}" if config[params[:server].to_sym][:targets].nil?

        target = config[params[:server].to_sym][:targets][params[:target].to_sym]
        raise "Could not find a target configuration for server #{params[:server]} and target #{params[:target]}" if target.nil?

        path = target[:path]
        raise "No path configured for target #{params[:target]}" if path.nil?

        job = nil
        log = Logger.log('RecoverJob')
        new_recover_opts = Hash.new
        new_recover_opts.merge!(params[:recover_opts]) if !params[:recover_opts].nil?
        new_recover_opts[:remote_ssh_cmd] = target[:remote_ssh_cmd] if target[:remote_ssh_cmd]
        if target[:recover_job_name]
          log.info("Trying to instantiate #{target[:recover_job_name]}")
          job = Object.const_get(target[:recover_job_name]).new(backup, path, new_recover_opts)
        else
          log.info("No recover_job_name defined, instantiating default RecoverJob")
          job = RecoverJob.new(backup, path, new_recover_opts)
        end
        return job
      end

      # convenient method to call {#before_recover}, {#recover} and {#after_recover}, in that order
      # @param [Hash] job_opts options which will be passed to {#before_recover}, {#recover} and {#after_recover}
      def perform!(job_opts = {})
        @log.info("Recovering backup #{@backup.id} for #{@backup.server}")
        before_recover(job_opts)
        recover(job_opts)
        after_recover(job_opts)
        @log.info("Recover finished")
      end

      # starts the recover process
      # @param [Hash] job_opts options hash
      # @option job_opts [Boolean] :report_progress whether to report the progress of the recover process. if set, {#report_progress} will be called every :report_interval seconds
      # @option job_opts [Integer] :report_interval defines the interval (in secs) for reporting the recover progress
      def recover(job_opts = {})
        if !job_opts[:report_progress]
          @backup.recover(@path, @recover_opts || {})
        else
          t = Thread.new { @backup.recover(@path, @recover_opts || {}) }
          t.abort_on_exception = true
          while t.alive?
            report_progress
            sleep job_opts[:report_interval] || 1
          end
        end
      end

      # will be executed before recover. the current implementation does nothing
      # @param [Hash] job_opts options hash
      # @return [void]
      def before_recover(job_opts = {})
      end

      # will be executed after recover. the current implementation does nothing
      # @param [Hash] job_opts options hash
      # @return [void]
      def after_recover(job_opts = {})
      end

      # reports the recover progress by logging a message with how many MB of the backup are copied at that time
      # @return [void]
      def report_progress
        backup_size = (@backup.size + @backup.wal_file_size) / 1024 ** 2
        if target_path_exists?
          du = target_path_disk_usage / 1024 ** 2
          @log.info("#{du} MB of #{backup_size} MB copied...")
        end
      end

      # if backup should be recovered to a remote host
      def remote_recover?
        return !(@recover_opts.nil? or @recover_opts[:remote_ssh_cmd].nil?)
      end

      # tries to delete the target directory defined by {#path}
      # @raise [RuntimeError] if {#path} is set to nil, "" or "/"
      # @retun [Boolean] if delete was successful or target directory doesn't exist
      def delete_target_path
        return true if !target_path_exists?
        raise RuntimeError, "Deleting path \"#{@path}\" is dangerous!" if @path == "/" || @path.to_s == ""
        cmd = create_cmd("rm -rf #{@path}")
        process = sh(cmd, { :abort_on_error => false })
        suc = exit_status_to_bool(process.status.exitstatus)
        if !suc
          raise RuntimeError, "Error while trying to delete path #{@path}: #{process.stderr}"
        end
        return suc
      end

      # determines the actual disk usage of the target directory defined by {#path}
      # @return [Integer] the disk usage in bytes
      def target_path_disk_usage
        cmd = create_cmd("du -bs #{@path}")
        du = sh(cmd).stdout.split("\n")[0].split("\t")[0].to_i
        return du
      end

      # @return [Boolean] whether the target directory exists defined by {#path}
      def target_path_exists?
        cmd = create_cmd("[ -d #{@path} ]")
        return exit_status_to_bool(sh(cmd, { :abort_on_error => false }).status.exitstatus)
      end

      # creates the target directory defined by {#path}, recursive
      # @return [Boolean] whether create was successful or true if target directory already exists
      # @raise [RuntimeError] if an error happens
      def create_target_path
        return true if target_path_exists?
        cmd = create_cmd("mkdir -p #{@path}")
        process = sh(cmd, { :abort_on_error => false })
        suc = exit_status_to_bool(process.status.exitstatus)
        if !suc
          raise RuntimeError, "Error while trying to create target path #{@path}: #{process.stderr}"
        end
        return suc
      end

      # converts a shell command exit status to bool
      # @param [String,Integer] exit_status the exit status reported by a shell command
      # @return [Boolean] the boolean representation of the exit status
      def exit_status_to_bool(exit_status)
        return exit_status.to_i == 0 ? true : false
      end

      # Prepends a ssh command to the cmd parameter if necessary
      # @return [String] the cmd with or without a prepended ssh command
      # @param [String] cmd the shell command which should be executed
      def create_cmd(cmd)
        return ssh_cmd.empty? ? cmd : "#{ssh_cmd} #{cmd}"
      end

      # @return [String] returns the remote ssh cmd defined in {#recover_opts} or empty if not set
      def ssh_cmd
        return remote_recover? ? @recover_opts[:remote_ssh_cmd] : ''
      end

      private

      def sh(cmd, opts = {})
        sh = Mixlib::ShellOut.new("#{cmd}")
        sh.timeout = 600 # 600 secs
        sh.run_command
        sh.error! if opts[:abort_on_error]
        return sh
      end

    end
  end
end

