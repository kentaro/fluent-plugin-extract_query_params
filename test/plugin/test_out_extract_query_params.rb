# -*- encoding: utf-8 -*-

require 'test_helper'

class ExtractQueryParamsOutputTest < Test::Unit::TestCase
  URL = 'http://example.com:80/?foo=bar&baz=qux&%E3%83%A2%E3%83%AA%E3%82%B9=%E3%81%99%E3%81%9F%E3%81%98%E3%81%8A'
  QUERY_ONLY = '?foo=bar&baz=qux&%E3%83%A2%E3%83%AA%E3%82%B9=%E3%81%99%E3%81%9F%E3%81%98%E3%81%8A'

  def setup
    Fluent::Test.setup
  end

  def create_driver(conf, tag = 'test')
    Fluent::Test::OutputTestDriver.new(
      Fluent::ExtractQueryParamsOutput, tag
    ).configure(conf)
  end

  def test_configure
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
      only           foo, baz
    ])

    assert_equal 'url',        d.instance.key
    assert_equal 'extracted.', d.instance.add_tag_prefix
    assert_equal 'foo, baz',   d.instance.only

    # when mandatory keys not set
    assert_raise(Fluent::ConfigError) do
      create_driver(%[
        key foo
      ])
    end
  end

  def test_filter_record
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
    ])

    tag    = 'test'
    record = {
      'url' => URL,
    }
    d.instance.filter_record('test', Time.now, record)

    assert_equal URL,       record['url']
    assert_equal 'bar',     record['foo']
    assert_equal 'qux',     record['baz']
    assert_equal 'すたじお', record['モリス']
  end

  def test_filter_record_with_field_prefix
    d = create_driver(%[
      key            url
      add_field_prefix query_
      add_tag_prefix extracted.
    ])

    tag    = 'test'
    record = {
      'url' => URL,
    }
    d.instance.filter_record('test', Time.now, record)

    assert_equal URL,       record['url']
    assert_nil record['foo']
    assert_nil record['baz']
    assert_nil record['モリス']
    assert_equal 'bar',     record['query_foo']
    assert_equal 'qux',     record['query_baz']
    assert_equal 'すたじお', record['query_モリス']
  end

  def test_filter_record_with_only
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
      only           foo, baz
    ])

    tag    = 'test'
    record = { 'url' => URL }
    d.instance.filter_record('test', Time.now, record)

    assert_equal URL,   record['url']
    assert_equal 'bar', record['foo']
    assert_equal 'qux', record['baz']
    assert_nil record['モリス']
  end

  def test_filter_record_with_except
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
      except         baz, モリス
    ])

    tag    = 'test'
    record = { 'url' => URL }
    d.instance.filter_record('test', Time.now, record)

    assert_equal URL,   record['url']
    assert_equal 'bar', record['foo']
    assert_nil record['baz']
    assert_nil record['モリス']
  end

  def test_filter_record_with_discard
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
      discard_key true
    ])

    tag    = 'test'
    record = { 'url' => URL }
    d.instance.filter_record('test', Time.now, record)

    assert_nil               record['nil']
    assert_nil               record['url']
    assert_equal 'bar',      record['foo']
    assert_equal 'qux',      record['baz']
    assert_equal 'すたじお', record['モリス']
  end

  def test_emit
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
      only           foo, baz
    ])
    d.run { d.emit('url' => URL) }
    emits = d.emits

    assert_equal 1, emits.count
    assert_equal 'extracted.test', emits[0][0]
    assert_equal URL,              emits[0][2]['url']
    assert_equal 'bar',            emits[0][2]['foo']
    assert_equal 'qux',            emits[0][2]['baz']
  end

  def test_emit_multi
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
      only           foo, baz
    ])
    d.run do
      d.emit('url' => URL)
      d.emit('url' => URL)
      d.emit('url' => URL)
    end
    emits = d.emits

    assert_equal 3, emits.count

    emits.each do |e|
      assert_equal 'extracted.test', e[0]
      assert_equal URL,              e[2]['url']
      assert_equal 'bar',            e[2]['foo']
      assert_equal 'qux',            e[2]['baz']
    end
  end

  def test_emit_without_match_key
    d = create_driver(%[
      key            no_such_key
      add_tag_prefix extracted.
      only           foo, baz
    ])
    d.run { d.emit('url' => URL) }
    emits = d.emits

    assert_equal 1, emits.count
    assert_equal 'extracted.test', emits[0][0]
    assert_equal URL,              emits[0][2]['url']
  end

  def test_emit_with_invalid_url
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.
    ])
    d.run { d.emit('url' => 'invalid url') }
    emits = d.emits

    assert_equal 1, emits.count
    assert_equal 'extracted.test', emits[0][0]
    assert_equal 'invalid url',    emits[0][2]['url']
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
    d = create_driver(%[
      key            path
      add_tag_prefix a.
    ])
    d.run {
      d.emit({ 'path' => DIRTY_PATH_BLANK_1 })
      d.emit({ 'path' => DIRTY_PATH_BLANK_2 })
      d.emit({ 'path' => DIRTY_PATH_BLANK_3 })
      d.emit({ 'path' => DIRTY_PATH_BLANK_4 })
      d.emit({ 'path' => DIRTY_PATH_KEY_ONLY_1 })
      d.emit({ 'path' => DIRTY_PATH_KEY_ONLY_2 })
      d.emit({ 'path' => DIRTY_PATH_KEY_ONLY_3 })
      d.emit({ 'path' => DIRTY_PATH_VALUE_ONLY_1 })
      d.emit({ 'path' => DIRTY_PATH_VALUE_ONLY_2 })
      d.emit({ 'path' => DIRTY_PATH_BASE64_1 })
      d.emit({ 'path' => DIRTY_PATH_BASE64_2 })
      d.emit({ 'path' => DIRTY_PATH_BASE64_3 })
      d.emit({ 'path' => DIRTY_PATH_BASE64_4 })
    }
    emits = d.emits

    assert_equal 13, emits.count

    r = emits.shift[2]
    assert_equal 2, r.size
    assert_equal DIRTY_PATH_BLANK_1, r['path']
    assert_equal 'qux',              r['baz']

    r = emits.shift[2]
    assert_equal 2, r.size
    assert_equal DIRTY_PATH_BLANK_2, r['path']
    assert_equal 'bar',              r['foo']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_BLANK_3, r['path']
    assert_equal 'bar',              r['foo']
    assert_equal 'qux',              r['baz']

    r = emits.shift[2]
    assert_equal 2, r.size
    assert_equal DIRTY_PATH_BLANK_4, r['path']
    assert_equal 'qux',              r['baz']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_KEY_ONLY_1, r['path']
    assert_equal '',                    r['foo']
    assert_equal 'qux',                 r['baz']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_KEY_ONLY_2, r['path']
    assert_equal '',                    r['foo']
    assert_equal 'qux',                 r['baz']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_KEY_ONLY_3, r['path']
    assert_equal '',                    r['foo']
    assert_equal 'qux',                 r['baz']

    r = emits.shift[2]
    assert_equal 2, r.size
    assert_equal DIRTY_PATH_VALUE_ONLY_1, r['path']
    assert_equal 'qux',                   r['baz']

    r = emits.shift[2]
    assert_equal 2, r.size
    assert_equal DIRTY_PATH_VALUE_ONLY_2, r['path']
    assert_equal 'qux',                   r['baz']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_BASE64_1, r['path']
    assert_equal 'qux',               r['baz']
    assert_equal 'ZXh0cmE=',          r['foo']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_BASE64_2, r['path']
    assert_equal 'qux',               r['baz']
    assert_equal 'ZXh0cmE=',          r['foo']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_BASE64_3, r['path']
    assert_equal 'qux',               r['baz']
    assert_equal 'cGFkZGluZw==',      r['foo']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_BASE64_4, r['path']
    assert_equal 'qux',               r['baz']
    assert_equal 'cGFkZGluZw==',      r['foo']
  end

  def test_emit_with_permit_blank_key
    d = create_driver(%[
      key              path
      add_tag_prefix   a.
      permit_blank_key yes
    ])
    d.run {
      d.emit({ 'path' => DIRTY_PATH_VALUE_ONLY_1 })
      d.emit({ 'path' => DIRTY_PATH_VALUE_ONLY_2 })
    }
    emits = d.emits

    assert_equal 2, emits.count

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_VALUE_ONLY_1, r['path']
    assert_equal 'bar',                   r['']
    assert_equal 'qux',                   r['baz']

    r = emits.shift[2]
    assert_equal 3, r.size
    assert_equal DIRTY_PATH_VALUE_ONLY_2, r['path']
    assert_equal 'bar',                   r['']
    assert_equal 'qux',                   r['baz']
  end

  def test_raw_multibyte_chars
    d = create_driver(%[
      key              path
      add_tag_prefix   a.
      permit_blank_key yes
    ])

    raw_multibytes_src = '/path/to/ほげぽす/x?a=b'

    d.run {
      d.emit({ 'path' => raw_multibytes_src.dup.encode('sjis').force_encoding('ascii-8bit') })
      d.emit({ 'path' => raw_multibytes_src.dup.encode('eucjp').force_encoding('ascii-8bit') })
    }
    emits = d.emits

    # nothing raised is correct
    assert_equal 2, emits.count

    r = emits.shift[2]
    assert_equal 2, r.size
    assert_equal 'b', r['a']

    r = emits.shift[2]
    assert_equal 2, r.size
    assert_equal 'b', r['a']
  end

  def test_filter_record_with_url_scheme_host_port_path
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.

      add_url_scheme true
      add_url_host true
      add_url_port true
      add_url_path true
    ])
    tag    = 'test'
    record = {
      'url' => URL,
    }
    d.instance.filter_record('test', Time.now, record)

    assert_equal URL,       record['url']
    assert_equal 'bar',     record['foo']
    assert_equal 'qux',     record['baz']
    assert_equal 'すたじお', record['モリス']
    assert_equal 'http',     record['url_scheme']
    assert_equal 'example.com', record['url_host']
    assert_equal 80,     record['url_port']
    assert_equal '/',     record['url_path']
  end

  def test_filter_record_with_field_prefix_and_url_scheme_host_port_path
    d = create_driver(%[
      key            url
      add_field_prefix query_
      add_tag_prefix extracted.

      add_url_scheme true
      add_url_host true
      add_url_port true
      add_url_path true
    ])

    tag    = 'test'
    record = {
      'url' => URL,
    }
    d.instance.filter_record('test', Time.now, record)

    assert_equal URL,       record['url']
    assert_nil record['foo']
    assert_nil record['baz']
    assert_nil record['モリス']
    assert_equal 'bar',     record['query_foo']
    assert_equal 'qux',     record['query_baz']
    assert_equal 'すたじお', record['query_モリス']
    assert_equal 'http',     record['query_url_scheme']
    assert_equal 'example.com', record['query_url_host']
    assert_equal 80,     record['query_url_port']
    assert_equal '/',     record['query_url_path']
  end

  def test_filter_record_from_query_only_url_with_url_scheme_host_port_path
    d = create_driver(%[
      key            url
      add_tag_prefix extracted.

      add_url_scheme true
      add_url_host true
      add_url_port true
      add_url_path true
    ])
    tag    = 'test'
    record = {
      'url' => QUERY_ONLY,
    }
    d.instance.filter_record('test', Time.now, record)

    assert_equal QUERY_ONLY, record['url']
    assert_equal 'bar',     record['foo']
    assert_equal 'qux',     record['baz']
    assert_equal 'すたじお', record['モリス']
    assert_equal '', record['url_scheme']
    assert_equal '', record['url_host']
    assert_equal '', record['url_port']
    assert_equal '', record['url_path']
  end
end
