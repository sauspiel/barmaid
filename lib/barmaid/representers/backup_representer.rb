module Barmaid
  module Representers
    module BackupRepresenter
      include Representable::JSON

      property :backup_start
      property :backup_end
      property :begin_wal
      property :end_wal
      property :server_id
      property :id
      property :pgdata
      property :server
      property :size
      property :status
      property :timeline
      property :wal_file_size
    end
  end
end
