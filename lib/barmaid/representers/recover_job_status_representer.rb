module Barmaid
  module Representers
    module RecoverJobStatusRepresenter
      include Representable::JSON

      property :status
      property :time
      property :message
      property :pct_complete
      property :server
      property :target
      property :backup_id
      property :completed_at
      property :id
    end
  end
end
