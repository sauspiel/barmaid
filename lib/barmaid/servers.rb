module RBarman
  class Servers
    def add_targets
      self.each do |srv|
        srv.add_targets
      end
    end
  end
end
