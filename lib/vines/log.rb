# encoding: UTF-8

module Vines
  module Log
    @@logger = nil
    def self.log(o=nil)
	if (o) then 
		@@logger=o
	else
		@@logger
	end
    end
    def log
      unless @@logger
        @@logger = Logger.new(STDOUT)
        @@logger.level = Logger::INFO
        @@logger.progname = 'vines'
        @@logger.formatter = Class.new(Logger::Formatter) do
          def initialize
            @time = "%Y-%m-%dT%H:%M:%SZ".freeze
            @fmt  = "[%s] %5s -- %s: %s\n".freeze
          end
          def call(severity, time, program, msg)
            @fmt % [time.utc.strftime(@time), severity, program, msg2str(msg)]
          end
        end.new
      end
      @@logger
    end
  end
end
