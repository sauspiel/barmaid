module Barmaid
  module Representers
    module BackupsRepresenter
      include Representable::JSON::Collection
      items extend: BackupRepresenter, class: RBarman::Backup
    end
  end
end
