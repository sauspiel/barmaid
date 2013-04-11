module Barmaid
  module Representers
    module TargetRepresenter
      include Representable::JSON

      property :id
      property :server_id
      property :path
      property :remote_ssh_cmd
      property :recover_job_name
    end
  end
end
