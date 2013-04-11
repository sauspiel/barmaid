module Barmaid
  module Representers
    module ServersRepresenter
      include Representable::JSON::Collection
      items extend: Barmaid::Representers::ServerRepresenter, class: RBarman::Server
    end
  end
end
