module Barmaid
  module Representers
    module BackupsRepresenter
      include Representable::JSON::Collection
      items extend: Barmaid::Representers::BackupRepresenter, class: RBarman::Backup
    end
  end
end
