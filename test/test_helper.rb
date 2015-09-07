require 'test/unit'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'fluent/test'

unless ENV.has_key?('VERBOSE')
  nulllogger = Object.new
  nulllogger.instance_eval {|obj|
    def method_missing(method, *args)
      # pass
    end
  }
  $log = nulllogger
end

require 'fluent/plugin/out_extract_query_params'

if Gem::Version.new(Fluent::VERSION) > Gem::Version.new('0.12')
  require 'fluent/plugin/filter_extract_query_params'
end

class Test::Unit::TestCase
end
