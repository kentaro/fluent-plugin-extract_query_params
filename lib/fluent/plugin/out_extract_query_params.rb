require 'uri'

module Fluent
  class ExtractQueryParamsOutput < Output
    include Fluent::HandleTagNameMixin

    Fluent::Plugin.register_output('extract_query_params', self)

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
      require 'webrick'
    end

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
        t = tag.dup
        filter_record(t, time, record)
        Engine.emit(t, time, record)
      end

      chain.next
    end

    def filter_record(tag, time, record)
      if record[key]
        begin
          url = begin
                  URI.parse(record[key])
                rescue URI::InvalidURIError => e
                  URI.parse(WEBrick::HTTPUtils.escape(record[key]))
                end

          if @add_url_scheme
            url_scheme_key = 'url_scheme'
            url_scheme_key = @add_field_prefix + url_scheme_key if @add_field_prefix
            record[url_scheme_key] = url.scheme || ''
          end

          if @add_url_host
            url_host_key = 'url_host'
            url_host_key = @add_field_prefix + url_host_key if @add_field_prefix
            record[url_host_key] = url.host || ''
          end

          if @add_url_port
            url_port_key = 'url_port'
            url_port_key = @add_field_prefix + url_port_key if @add_field_prefix
            record[url_port_key] = url.port || ''
          end

          if @add_url_path
            url_path_key = 'url_path'
            url_path_key = @add_field_prefix + url_path_key if @add_field_prefix
            record[url_path_key] = url.path || ''
          end

          unless url.query.nil?
            url.query.split('&').each do |pair|
              key, value = pair.split('=', 2).map { |i| URI.unescape(i) }
              next if (key.nil? || key.empty?) && (!@permit_blank_key || value.nil? || value.empty?)
              key ||= ''
              value ||= ''

              key = @add_field_prefix + key if @add_field_prefix
              if only
                record[key] = value if @include_keys.has_key?(key)
              elsif except
                record[key] = value if !@exclude_keys.has_key?(key)
              else
                record[key] = value
              end
            end
          end
          record.delete key if discard_key
        rescue URI::InvalidURIError => error
          $log.warn("out_extract_query_params: #{error.message}")
        end
      end

      super(tag, time, record)
    end
  end
end
