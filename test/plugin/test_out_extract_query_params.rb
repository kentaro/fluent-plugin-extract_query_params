# -*- encoding: utf-8 -*-

require 'test_helper'

class ExtractQueryParamsOutputTest < Test::Unit::TestCase
  URL = 'http://example.com/?foo=bar&baz=qux&%E3%83%A2%E3%83%AA%E3%82%B9=%E3%81%99%E3%81%9F%E3%81%98%E3%81%8A'

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
end
