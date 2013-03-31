module Barmaid

  class ShellCommand

    # represents the result of a command
    class ShellCommandResult

      # @return [String] the command
      attr_accessor :cmd

      # @return [String] the command's output to stdout
      attr_accessor :stdout

      # @return [String] the command's output to stdout
      attr_accessor :stderr

      # @return [Integer] the command's exit code
      attr_accessor :exit_code

      # creates a new instance of [ShellCommandResult]
      # @param [String] the command
      # @param [String] the command's output to stdout
      # @param [String] the command's output to stderr
      # @param [Integer] the command's exit code
      def initialize(cmd, stdout, stderr, exit_code)
        @cmd = cmd
        @stdout = stdout
        @stderr = stderr
        @exit_code = exit_code
      end

      # Hash-like method to access keys in the +[]+ syntax.
      def [](key) self.send(key) end

      # Hash-like method to access keys in the +[]=+ syntax.
      def []=(key, value) self.send("#{key}=", value) end

      def to_s
        return "Command: \"#{@cmd}\", stdout: \"#{@stdout}\", stderr: \"#{@stderr}\", exit_code: \"#{@exit_code}\""
      end

      def succeeded?
        return @exit_code.to_i == 0 ? true : false
      end

    end


    # @return [String] the command
    attr_accessor :cmd

    # @return [ShellCommandResult] the command's execution result
    attr_reader :result

    # initializes a new instance of {ShellCommand}
    # @param [String] cmd the command to be executed
    def initialize(cmd)
      @cmd = cmd
    end

    # executes the command local
    # @param [Hash] opts options hash
    # @option opts [Boolean] :abort_on_error whether an exception should be raised when exit code != 0
    def exec_local(opts = {})
      sh = Mixlib::ShellOut.new("#{cmd}")
      sh.timeout = 60 * 60 * 24 # 24hours
      sh.run_command

      @result = ShellCommandResult.new(@cmd, sh.stdout, sh.stderr, sh.exitstatus.to_i)

      raise_error! if opts[:abort_on_error]

      return @result
    end

    # executes the command via ssh
    # @param [String] host the host to which the connection should be made
    # @param [String] user the username which should be used for ssh connection
    # @param [Net::SSH::Connection::Session] session the session which will be used when given, otherwise a new session will be opened
    # @param [Hash] opts options hash
    # @option opts [Boolean] :abort_on_error whether an exception should be raised when exit code != 0
    # @raise [RuntimeError] if :abort_on_error is specified and exit code != 0
    def exec_ssh(host, user, session = nil, opts = {})

      stdout_data, stderr_data = "", ""
      exit_code, exit_signal = nil, nil
      cur_session = session.nil? ? ::Net::SSH.start(host, user) : session
      cur_session.open_channel do |channel|
        channel.exec(@cmd) do |_, success|
          raise RuntimeError, "Command \"#{@cmd}\" could not be executed!" if !success

          channel.on_data do |_, data|
            stdout_data += data
          end

          channel.on_extended_data do |_,_,data|
            stderr_data += data
          end

          channel.on_request("exit-status") do |_,data|
            exit_code = data.read_long
          end

          channel.on_request("exit-signal") do |_, data|
            exit_signal = data.read_long
          end
        end
      end
      cur_session.loop

      @result = ShellCommandResult.new(@cmd, stdout_data, stderr_data, exit_code.to_i)

      cur_session.close if session.nil?

      raise_error! if opts[:abort_on_error]

      return @result
    end

    # raises an exception when exit code != 0
    # @raise [RuntimeError]
    def raise_error!
      raise RuntimeError, "Command failed! #{@result.to_s}" if @result.exit_code != 0
    end
  end
end
