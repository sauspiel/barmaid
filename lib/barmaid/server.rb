module RBarman
  class Server
    attr_accessor :targets

    def id
      return @name
    end

    def add_targets
      return if !Barmaid::Config.config[:servers][id.to_sym]
      targets = Barmaid::Config.config[:servers][id.to_sym][:targets]
      if targets
        @targets = Array.new
        targets.each do |k,v|
          @targets << Barmaid::Target.new(k.to_s, id, v)
        end
      end
    end
  end

  class Servers
    
    def add_targets
      self.each do |srv|
        srv.add_targets
      end
    end

  end
end
