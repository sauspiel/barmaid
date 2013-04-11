module Barmaid
  module Representers
    module ServerRepresenter
      include Representable::JSON

      property :active
      property :backup_dir
      property :base_backups_dir
      property :conn_info
      property :name
      property :pg_conn_ok
      property :ssh_check_ok
      property :ssh_cmd
      property :wals_dir
      property :id

      collection :backups, :class => RBarman::Backup
    end

    module ServersRepresenter
      include Representable::JSON::Collection
      items extend: ServerRepresenter, class: RBarman::Server
    end
  end
end
