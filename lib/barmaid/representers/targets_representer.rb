module Barmaid
  module Representers
    module TargetsRepresenter
      include Representable::JSON::Collection
      items extend: Barmaid::Representers::TargetRepresenter, class: Barmaid::Target
    end
  end
end
