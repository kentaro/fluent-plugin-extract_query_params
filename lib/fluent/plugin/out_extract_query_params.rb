require 'uri'

module Fluent
  class ExtractQueryParamsOutput < Output
    include Fluent::HandleTagNameMixin

    Fluent::Plugin.register_output('extract_query_params', self)

    config_param :key,    :string
    config_param :only,   :string, :default => nil
    config_param :except, :string, :default => nil

    def configure(conf)
      super

      if (
          !remove_tag_prefix &&
          !remove_tag_suffix &&
          !add_tag_prefix    &&
          !add_tag_suffix
      )
        raise ConfigError, "out_extract_query_params: At least one of remove_tag_prefix/remove_tag_suffix/add_tag_prefix/add_tag_suffix is required to be set."
      end

      @include_keys = only   && only.split(/\s*,\s*/).inject({}) do |hash, i|
        hash[i] = true
        hash
      end
      @exclude_keys = except && except.split(/\s*,\s*/).inject({}) do |hash, i|
        hash[i] = true
        hash
      end
    end

    def emit(tag, es, chain)
      es.each do |time, record|
        filter_record(tag, time, record)
        Engine.emit(tag, time, record)
      end

      chain.next
    end

    def filter_record(tag, time, record)
      if record[key]
        begin
          url = URI.parse(record[key])
          url.query.split('&').each do |pair|
            key, value = pair.split('=').map { |i| URI.unescape(i) }

            if only
              record[key] = value if @include_keys.has_key?(key)
            elsif except
              record[key] = value if !@exclude_keys.has_key?(key)
            else
              record[key] = value
            end
          end
        rescue URI::InvalidURIError => error
          $log.warn("out_extract_query_params: #{error.message}")
        end
      end

      super(tag, time, record)
    end
  end
end
