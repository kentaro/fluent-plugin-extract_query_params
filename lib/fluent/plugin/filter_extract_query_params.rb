module Fluent
  class ExtractQueryParamsFilter < Filter

    Fluent::Plugin.register_filter('extract_query_params', self)

    config_param :key,    :string
    config_param :only,   :string, :default => nil
    config_param :except, :string, :default => nil
    config_param :discard_key, :bool, :default => false
    config_param :add_field_prefix, :string, :default => nil
    config_param :permit_blank_key, :bool, :default => false

    config_param :add_url_scheme, :bool, :default => false
    config_param :add_url_host, :bool, :default => false
    config_param :add_url_port, :bool, :default => false
    config_param :add_url_path, :bool, :default => false

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
