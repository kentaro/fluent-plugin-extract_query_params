require 'uri'
require 'cgi/util'
require 'webrick'

module Fluent
  class QueryParamsExtractor

    attr_reader :log

    def initialize(plugin, conf)
      @log = plugin.log

      if plugin.is_a?(Fluent::Output)
        unless have_tag_option?(plugin)
          raise ConfigError, "out_extract_query_params: At least one of remove_tag_prefix/remove_tag_suffix/add_tag_prefix/add_tag_suffix is required to be set."
        end
      end

      @key = plugin.key
      @only = plugin.only
      @except = plugin.except
      @discard_key = plugin.discard_key
      @add_field_prefix = plugin.add_field_prefix
      @permit_blank_key = plugin.permit_blank_key

      @add_url_scheme = plugin.add_url_scheme
      @add_url_host = plugin.add_url_host
      @add_url_port = plugin.add_url_port
      @add_url_path = plugin.add_url_path

      if @only
        @include_keys = @only.split(/\s*,\s*/).inject({}) do |hash, i|
          hash[i] = true
          hash
        end
      end

      if @except
        @exclude_keys = @except.split(/\s*,\s*/).inject({}) do |hash, i|
          hash[i] = true
          hash
        end
      end
    end

    def add_query_params_field(record)
      return record unless record[@key]
      url = parse_url(record[@key])
      add_url_scheme(url, record)
      add_url_host(url, record)
      add_url_port(url, record)
      add_url_path(url, record)
      add_query_params(url, record)
      record.delete(@key) if @discard_key
      record
    end

    private

    def have_tag_option?(plugin)
      plugin.remove_tag_prefix ||
        plugin.remove_tag_suffix ||
        plugin.add_tag_prefix    ||
        plugin.add_tag_suffix
    end

    def parse_url(url_string)
      URI.parse(url_string)
    rescue URI::InvalidURIError
      URI.parse(WEBrick::HTTPUtils.escape(url_string))
    end

    def create_field_key(field_key)
      if add_field_prefix?
        "#{@add_field_prefix}#{field_key}"
      else
        field_key
      end
    end

    def add_url_scheme(url, record)
      return unless @add_url_scheme
      url_scheme_key = create_field_key('url_scheme')
      record[url_scheme_key] = url.scheme || ''
    end

    def add_url_host(url, record)
      return unless @add_url_host
      url_host_key = create_field_key('url_host')
      record[url_host_key] = url.host || ''
    end

    def add_url_port(url, record)
      return unless @add_url_port
      url_port_key = create_field_key('url_port')
      record[url_port_key] = url.port || ''
    end

    def add_url_path(url, record)
      return unless @add_url_path
      url_path_key = create_field_key('url_path')
      record[url_path_key] = url.path || ''
    end

    def add_field_prefix?
      !!@add_field_prefix
    end

    def permit_blank_key?
      @permit_blank_key
    end

    def add_query_params(url, record)
      return if url.query.nil?
      url.query.split('&').each do |pair|
        key, value = pair.split('=', 2).map { |i| CGI.unescape(i) }
        next if (key.nil? || key.empty?) && (!permit_blank_key? || value.nil? || value.empty?)
        key ||= ''
        value ||= ''

        key = create_field_key(key)
        if @only
          record[key] = value if @include_keys.has_key?(key)
        elsif @except
          record[key] = value if !@exclude_keys.has_key?(key)
        else
          record[key] = value
        end
      end
    end
  end
end
