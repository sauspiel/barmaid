module Barmaid
  class Target
    attr_accessor :id
    attr_accessor :server_id
    attr_accessor :path
    attr_accessor :remote_ssh_cmd
    attr_accessor :recover_job_name

    def initialize(id, server_id, opts = {})
      @id = id
      @server_id = server_id
      parse_opts(opts)
    end

    def parse_opts(opts = {})
      @path = opts[:path]
      @remote_ssh_cmd = opts[:remote_ssh_cmd]
      @recover_job_name = opts[:recover_job_name]
    end
  end
end
