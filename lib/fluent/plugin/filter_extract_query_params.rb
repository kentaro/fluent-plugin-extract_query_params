module Fluent
  class ExtractQueryParamsFilter < Filter

    Fluent::Plugin.register_filter('extract_query_params', self)

    # For fluentd v0.12.16 or earlier
    class << self
      unless method_defined?(:desc)
        def desc(description)
        end
      end
    end

    desc "point a key whose value contains URL string."
    config_param :key,    :string
    desc "If set, only the key/value whose key is included only will be added to the record."
    config_param :only,   :string, default: nil
    desc "If set, the key/value whose key is included except will NOT be added to the record."
    config_param :except, :string, default: nil
    desc "If set to true, the original key url will be discarded from the record."
    config_param :discard_key, :bool, default: false
    desc "Prefix of fields."
    config_param :add_field_prefix, :string, default: nil
    desc "If set to true, permit blank key."
    config_param :permit_blank_key, :bool, default: false

    desc "If set to true, scheme (use url_scheme key) will be added to the record."
    config_param :add_url_scheme, :bool, default: false
    desc "If set to true, host (use url_host key) will be added to the record."
    config_param :add_url_host, :bool, default: false
    desc "If set to true, port (use url_port key) will be added to the record."
    config_param :add_url_port, :bool, default: false
    desc "If set to true, path (use url_path key) will be added to the record."
    config_param :add_url_path, :bool, default: false

    def initialize
      super
      require 'fluent/plugin/query_params_extractor'
    end

    def configure(conf)
      super
      @extractor = QueryParamsExtractor.new(self, conf)
    end

    def filter(tag, time, record)
      @extractor.add_query_params_field(record)
    end
  end
end
