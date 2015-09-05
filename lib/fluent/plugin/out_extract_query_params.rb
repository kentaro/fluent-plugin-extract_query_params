module Fluent
  class ExtractQueryParamsOutput < Output
    include Fluent::HandleTagNameMixin

    Fluent::Plugin.register_output('extract_query_params', self)

    # To support Fluentd v0.10.57 or earlier
    unless method_defined?(:router)
      define_method("router") { Fluent::Engine }
    end

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
      require 'fluent/plugin/query_params_extractor'
      super
    end

    def configure(conf)
      super
      @extractor = QueryParamsExtractor.new(self, conf)
    end

    def filter_record(tag, time, record)
      record = @extractor.add_query_params_field(record)
      super(tag, time, record)
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        t = tag.dup
        filter_record(t, time, record)
        router.emit(t, time, record)
      end

      chain.next
    end
  end
end
