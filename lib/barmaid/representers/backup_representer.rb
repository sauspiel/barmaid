module Barmaid
  module Representers
    module BackupRepresenter
      include Representable::JSON

      property :backup_start
      property :backup_end
      property :id
      property :pgdata
      property :server, as: :server_id
      property :size
      property :status
      property :timeline
      property :wal_file_size
    end
  end
end
