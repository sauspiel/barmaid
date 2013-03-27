require 'mixlib/shellout'

module Barmaid
  module Job
    class RecoverJob
      include Resque::Plugins::Status

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
      # @param [String] uuid the unique id of the job
      # @param [Hash] options options
      def initialize(uuid = nil, options = {})
        @recover_opts = options[:recover_opts] || {}
        @log = RecoverJob.logger
        super(uuid, options)
      end
      
      # @return [Log4r::Logger] returns a Log4r::Logger object
      def self.logger
        return Logger.log('RecoverJob')
      end

      # converts all string keys in the given hash to symbols
      # @param [Hash] hash the hash
      # @return [Hash] a new hash with symbols
      def self.hash_strings_to_sym(hash)
        return hash.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
      end

      # factory method to create a RecoverJob or a subclass of it by using configuration settings
      # @param [String] uuid the UUID which should be applied to the job to identify the job later (mainly used for resque-status)
      # @param [Hash] params the parameters for creating a new {RecoverJob}
      # @option params [String] :server the name of the server which includes the backup
      # @option params [String] :target to which target the backup should be recovered
      # @option params [String] :backup_id id of the backup which should be recoverd
      # @option params [Hash] :recover_opts options passed to the recovering process (see {http://rubydoc.info/gems/rbarman/RBarman/Backup:recover RBarman::Backup#recover})
      # @raise [RuntimeError] if no server configuration according to params[:server] could be found
      # @raise [RuntimeError] if params do not contain a :target definition
      # @raise [RuntimeError] if :target is not configured for the specified server
      # @raise [RuntimeError] if no target configuration according to params[:target] could be found
      # @raise [RuntimeError] if no path configuration could be found
      # @return [RecoverJob]
      # @note this method requires that params contains a :target with a string value to identify the required target settings from the configuration. Also params[:recover_opts][:remote_ssh_cmd] and params[:recover_opts][:path], if given, will be overwritten by the according settings from configuration. If the configuration contains a "recover_job_name" setting, this method tries to instantiate an object with that name and returns that, otherwise an instance of RecoverJob will be returned
      def self.create_job_by_configuration(uuid, params)

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
        log = RecoverJob.logger
        new_opts = Hash.new
        new_opts.merge!(params)
        new_opts[:recover_opts] = {} if new_opts[:recover_opts].nil?
        new_opts[:recover_opts][:remote_ssh_cmd] = target[:remote_ssh_cmd] if target[:remote_ssh_cmd]
        if target[:recover_job_name]
          log.info("Trying to instantiate #{target[:recover_job_name]}")
          job = Object.const_get(target[:recover_job_name]).new(uuid, new_opts)
        else
          log.info("No recover_job_name defined, instantiating default RecoverJob")
          job = RecoverJob.new(uuid, new_opts)
        end
        job.path = path
        job.assign_backup(new_opts[:server], new_opts[:backup_id])
        return job
      end

      # convenient method to call {#before_recover}, {#recover} and {#after_recover}, in that order
      def execute
        log = RecoverJob.logger
        log.info("Recovering backup #{@backup.id} for #{@backup.server} (options: #{@options.to_json}) (uuid #{@uuid})")
        before_recover
        recover
        after_recover
        msg = "Recover of backup #{@backup.id} for #{@backup.server} (uuid #{@uuid}) finished"
        log.info(msg)

        completed({:message => msg, :completed_at => Time.now})
      end

      # assings a {RBarman::Backup} to {#backup}
      # @param [String] server the server name
      # @param [String] backup_id the id of the backup
      # @raise [RuntimeError] if no backup could be found
      # @return [void]
      def assign_backup(server, backup_id)
        backup = RBarman::Backup.by_id(server, backup_id, { :with_wal_files => true })
        raise "No backup with id #{backup_id} for server #{server} found!" if backup.nil?
        @backup = backup
      end

      # this method will be called by resque workers
      # @return [void]
      def perform
        begin
          data = RecoverJob.hash_strings_to_sym(options)
          job = RecoverJob.create_job_by_configuration(@uuid, data)
          job.execute
        rescue => e
          RecoverJob.logger.error(e.message)
          RecoverJob.logger.error(e.backtrace.join("\n"))
          # reraise exception so that caller (resque worker?) recognizes errors
          raise e
        end
      end

      # starts the recover process
      def recover
        t = Thread.new { @backup.recover(@path, @recover_opts || {}) }
        t.abort_on_exception = true
        while t.alive?
          report_progress
          sleep options[:report_interval] || 5
        end
      end

      # will be executed before recover. the current implementation does nothing
      # @return [void]
      def before_recover
      end

      # will be executed after recover. the current implementation does nothing
      # @return [void]
      def after_recover
      end

      # reports the recover progress by setting status for resque-status and logging a message to stdout
      # @return [void]
      def report_progress
        backup_size = (@backup.size + @backup.wal_file_size) / 1024 ** 2
        du = target_path_exists? ? target_path_disk_usage / 1024 ** 2 : 0
        percent = du.to_f / backup_size.to_f * 100
        percent = 100.0 if percent >= 100.0
        message = "#{percent.to_i}% of Backup #{@backup.id} (#{@backup.server}) recovered" 
        at(percent.to_i, 100, message)
        @log.info(message)
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

