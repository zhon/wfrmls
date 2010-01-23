require 'optparse'
require 'wfrmls'

module Wfrmls #:nodoc:
  module CLI #:nodoc:
    class Options #:nodoc:
      class << self
        alias_method :parse!, :new
      end
      
      attr_reader :address
    
      def initialize(*args)
        address = ''

        argv = args.flatten
        
        opt = OptionParser.new do |opt|
          opt.banner = "Usage: #{script_name} [options] <address>"
          opt.version = version

          #opt.on("-r [PATH]", "Require [PATH] before executing") do |path|
          #  @paths_to_require << path
          #end
      
          opt.on("-h", "-?", "--help", "Show this message") do
            puts opt
            exit
          end
      
          opt.on("-v", "--version", "Show #{script_name}'s version (#{version})") do
            puts version
            exit
          end  
        end
        
        opt.parse!(argv)
        @address = argv.dup.join(' ')
      end 

      def version
        Wfrmls::VERSION
      end

      def script_name
        @script_name ||= File.basename($0)
        @script_name
      end
    end
  end
end

