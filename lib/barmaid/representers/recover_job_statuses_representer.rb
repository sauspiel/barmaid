module Barmaid
  module Representers
    module RecoverJobStatusesRepresenter
      include Representable::JSON::Collection
      items extend: Barmaid::Representers::RecoverJobStatusRepresenter, class: Barmaid::RecoverJobStatus
    end
  end
end
