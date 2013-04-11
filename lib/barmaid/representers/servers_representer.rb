module Barmaid
  module Representers
    module ServersRepresenter
      include Representable::JSON::Collection
      items extend: ServerRepresenter, class: RBarman::Server
    end
  end
end
