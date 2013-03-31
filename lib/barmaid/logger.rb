require 'log4r'

module Barmaid
  class Logger
    def self.log(name)
      return self.init_logger(name)
    end

    def self.init_logger(name)
      log = Log4r::Logger[name]
      if log.nil?
        log = Log4r::Logger.new name
        outputter = Log4r::Outputter.stdout
        outputter.formatter = Log4r::PatternFormatter.new(:pattern => "%d - %m")
        log.outputters = outputter
      end
      return log
    end
  end
end
