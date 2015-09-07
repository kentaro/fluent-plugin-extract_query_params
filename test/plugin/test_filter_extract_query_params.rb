require 'test_helper'

class ExtractQueryParamsFilterTest < Test::Unit::TestCase
  URL = 'http://example.com:80/?foo=bar&baz=qux&%E3%83%A2%E3%83%AA%E3%82%B9=%E3%81%99%E3%81%9F%E3%81%98%E3%81%8A'
  QUERY_ONLY = '?foo=bar&baz=qux&%E3%83%A2%E3%83%AA%E3%82%B9=%E3%81%99%E3%81%9F%E3%81%98%E3%81%8A'

  def setup
    Fluent::Test.setup
    @time = Fluent::Engine.now
  end

  def create_driver(conf, tag = 'test')
    Fluent::Test::FilterTestDriver.new(
      Fluent::ExtractQueryParamsFilter, tag
    ).configure(conf)
  end

  def filter(config, messages)
    d = create_driver(config, 'test')
    d.run {
      messages.each {|message|
        d.filter(message, @time)
      }
    }
    filtered = d.filtered_as_array
    filtered.map {|m| m[2] }
  end

  def test_configure
    d = create_driver(%[
      key            url
      only           foo, baz
    ])

    assert_equal 'url',        d.instance.key
    assert_equal 'foo, baz',   d.instance.only
  end

  def test_filter
    config = %[
      key            url
    ]

    record = {
      'url' => URL,
    }
    expected = {
      'url' => URL,
      'foo' => 'bar',
      'baz' => 'qux',
      'モリス' => 'すたじお'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_field_prefix
    config = %[
      key            url
      add_field_prefix query_
    ]

    record = {
      'url' => URL,
    }
    expected = {
      'url' => URL,
      'query_foo' => 'bar',
      'query_baz' => 'qux',
      'query_モリス' => 'すたじお'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_only
    config = %[
      key            url
      only           foo, baz
    ]

    record = { 'url' => URL }
    expected = {
      'url' => URL,
      'foo' => 'bar',
      'baz' => 'qux',
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_except
    config = %[
      key            url
      except         baz, モリス
    ]

    record = { 'url' => URL }
    expected = {
      'url' => URL,
      'foo' => 'bar',
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_discard
    config = %[
      key            url
      discard_key true
    ]

    record = { 'url' => URL }
    expected = {
      'foo' => 'bar',
      'baz' => 'qux',
      'モリス' => 'すたじお'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_multi_records
    config = %[
      key            url
      only           foo, baz
    ]
    records = [
      { 'url' => URL },
      { 'url' => URL },
      { 'url' => URL }
    ]
    expected = [
      { 'url' => URL, 'foo' => 'bar', 'baz' => 'qux' },
      { 'url' => URL, 'foo' => 'bar', 'baz' => 'qux' },
      { 'url' => URL, 'foo' => 'bar', 'baz' => 'qux' }
    ]
    filtered = filter(config, records)
    assert_equal(expected, filtered)
  end

  def test_emit_without_match_key
    config = %[
      key            no_such_key
      only           foo, baz
    ]
    record = { 'url' => URL }
    filtered = filter(config, [record])
    assert_equal(record, filtered[0])
  end

  def test_emit_with_invalid_url
    config = %[
      key            url
    ]
    record = { 'url' => URL }
    filtered = filter(config, [record])
    assert_equal([record], filtered)
  end

  DIRTY_PATH_BLANK_1 = '/dummy?&baz=qux'
  DIRTY_PATH_BLANK_2 = '/dummy?foo=bar&'
  DIRTY_PATH_BLANK_3 = '/dummy?foo=bar&&baz=qux'
  DIRTY_PATH_BLANK_4 = '/dummy?=&baz=qux'
  DIRTY_PATH_KEY_ONLY_1 = '/dummy?foo=&baz=qux'
  DIRTY_PATH_KEY_ONLY_2 = '/dummy?foo&baz=qux'
  DIRTY_PATH_KEY_ONLY_3 = '/dummy?baz=qux&foo'
  DIRTY_PATH_VALUE_ONLY_1 = '/dummy?=bar&baz=qux'
  DIRTY_PATH_VALUE_ONLY_2 = '/dummy?baz=qux&=bar'
  DIRTY_PATH_BASE64_1 = '/dummy?foo=ZXh0cmE=&baz=qux'
  DIRTY_PATH_BASE64_2 = '/dummy?baz=qux&foo=ZXh0cmE='
  DIRTY_PATH_BASE64_3 = '/dummy?foo=cGFkZGluZw==&baz=qux'
  DIRTY_PATH_BASE64_4 = '/dummy?baz=qux&foo=cGFkZGluZw=='

  def test_emit_with_dirty_paths
    config = %[
      key            path
    ]
    records = [
      { 'path' => DIRTY_PATH_BLANK_1 },
      { 'path' => DIRTY_PATH_BLANK_2 },
      { 'path' => DIRTY_PATH_BLANK_3 },
      { 'path' => DIRTY_PATH_BLANK_4 },
      { 'path' => DIRTY_PATH_KEY_ONLY_1 },
      { 'path' => DIRTY_PATH_KEY_ONLY_2 },
      { 'path' => DIRTY_PATH_KEY_ONLY_3 },
      { 'path' => DIRTY_PATH_VALUE_ONLY_1 },
      { 'path' => DIRTY_PATH_VALUE_ONLY_2 },
      { 'path' => DIRTY_PATH_BASE64_1 },
      { 'path' => DIRTY_PATH_BASE64_2 },
      { 'path' => DIRTY_PATH_BASE64_3 },
      { 'path' => DIRTY_PATH_BASE64_4 }
    ]
    expected = [
      { 'path' => DIRTY_PATH_BLANK_1, 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_BLANK_2, 'foo' => 'bar' },
      { 'path' => DIRTY_PATH_BLANK_3, 'foo' => 'bar', 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_BLANK_4, 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_KEY_ONLY_1, 'foo' => '', 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_KEY_ONLY_2, 'foo' => '', 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_KEY_ONLY_3, 'foo' => '', 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_VALUE_ONLY_1, 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_VALUE_ONLY_2, 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_BASE64_1, 'baz' => 'qux', 'foo' => 'ZXh0cmE=' },
      { 'path' => DIRTY_PATH_BASE64_2, 'baz' => 'qux', 'foo' => 'ZXh0cmE=' },
      { 'path' => DIRTY_PATH_BASE64_3, 'baz' => 'qux', 'foo' => 'cGFkZGluZw==' },
      { 'path' => DIRTY_PATH_BASE64_4, 'baz' => 'qux', 'foo' => 'cGFkZGluZw==' }
    ]
    filtered = filter(config, records)
    assert_equal(expected, filtered)
  end

  def test_emit_with_permit_blank_key
    config = %[
      key              path
      permit_blank_key yes
    ]
    records = [
      { 'path' => DIRTY_PATH_VALUE_ONLY_1 },
      { 'path' => DIRTY_PATH_VALUE_ONLY_2 }
    ]
    expected = [
      { 'path' => DIRTY_PATH_VALUE_ONLY_1, '' => 'bar', 'baz' => 'qux' },
      { 'path' => DIRTY_PATH_VALUE_ONLY_2, '' => 'bar', 'baz' => 'qux' }
    ]
    filtered = filter(config, records)
    assert_equal(expected, filtered)
  end

  def test_raw_multibyte_chars
    config = %[
      key              path
      permit_blank_key yes
    ]

    raw_multibytes_src = '/path/to/ほげぽす/x?a=b'

   records = [
      { 'path' => raw_multibytes_src.dup.encode('sjis').force_encoding('ascii-8bit') },
      { 'path' => raw_multibytes_src.dup.encode('eucjp').force_encoding('ascii-8bit') }
    ]
    expected = [
      { 'path' => raw_multibytes_src.dup.encode('sjis').force_encoding('ascii-8bit'), 'a' => 'b' },
      { 'path' => raw_multibytes_src.dup.encode('eucjp').force_encoding('ascii-8bit'), 'a' => 'b' }
    ]
    filtered = filter(config, records)
    assert_equal(expected, filtered)
  end

  def test_filter_with_url_scheme_host_port_path
    config = %[
      key            url

      add_url_scheme true
      add_url_host true
      add_url_port true
      add_url_path true
    ]

    record = {
      'url' => URL,
    }
    expected = {
      'url' => URL,
      'foo' => 'bar',
      'baz' => 'qux',
      'モリス' => 'すたじお',
      'url_scheme' => 'http',
      'url_host' => 'example.com',
      'url_port' => 80,
      'url_path' => '/'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_with_field_prefix_and_url_scheme_host_port_path
    config = %[
      key            url
      add_field_prefix query_

      add_url_scheme true
      add_url_host true
      add_url_port true
      add_url_path true
    ]

    record = {
      'url' => URL,
    }
    expected = {
      'url' => URL,
      'query_foo' => 'bar',
      'query_baz' => 'qux',
      'query_モリス' => 'すたじお',
      'query_url_scheme' => 'http',
      'query_url_host' => 'example.com',
      'query_url_port' => 80,
      'query_url_path' => '/'
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end

  def test_filter_from_query_only_url_with_url_scheme_host_port_path
    config = %[
      key            url

      add_url_scheme true
      add_url_host true
      add_url_port true
      add_url_path true
    ]
    record = {
      'url' => QUERY_ONLY,
    }
    expected = {
      'url' => QUERY_ONLY,
      'foo' => 'bar',
      'baz' => 'qux',
      'モリス' => 'すたじお',
      'url_scheme' => '',
      'url_host' => '',
      'url_port' => '',
      'url_path' => ''
    }
    filtered = filter(config, [record])
    assert_equal(expected, filtered[0])
  end
end
