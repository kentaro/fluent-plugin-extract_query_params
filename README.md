# fluent-plugin-extract_query_params, a plugin for [Fluentd](http://fluentd.org) [![](https://travis-ci.org/kentaro/fluent-plugin-extract_query_params.svg)](https://travis-ci.org/kentaro/fluent-plugin-extract_query_params)

## Component

### ExtractQueryParamsOutput

Fluentd plugin to extract key/values from URL query parameters.

## Requirements

| fluent-plugin-extract_query_params | fluentd    | ruby   |
|------------------------------------|------------|--------|
| >= 0.1.0                           | >= v0.14.0 | >= 2.1 |
| < 0.1.0                            | >= v0.12.0 | >= 1.9 |

**Caveat**: This plugin, from version 0.1.0, supports fluentd of version v0.14 or higher.
If you want to use this plugin with fluentd v0.12 or earlier, choose 0.0.x versions.

## Synopsis

Imagin you have a config as below:

```
<filter test.**>
  @type extract_query_params

  key            url
  only           foo, baz
</filter>
```

And you feed such a value into fluentd:

```
"test" => {
  "url" => "http://example.com/?foo=bar&baz=qux&hoge=fuga"
}
```

Then you'll get re-emmited tag/record-s below:

```
"test" => {
  "url" => "http://example.com/?foo=bar&baz=qux&hoge=fuga"
  "foo" => "bar",
  "baz" => "qux"
}
```

`hoge` parameter is not extracted.

## Configuration

### key

`key` is used to point a key whose value contains URL string.

### remove_tag_prefix, remove_tag_suffix, add_tag_prefix, add_tag_suffix

These params are included from `Fluent::HandleTagNameMixin`. See the code for details.

You must add at least one of these params.

### only

If set, only the key/value whose key is included `only` will be added to the record.

### except

If set, the key/value whose key is included `except` will NOT be added to the record.

### discard_key

If set to `true`, the original `key` url will be discarded from the record. Defaults to `false` (preserve key).

### add_url_scheme

If set to `true`, scheme (use `url_scheme` key) will be added to the record. Defaults to `false`.

### add_url_host

If set to `true`, host (use `url_host` key) will be added to the record. Defaults to `false`.

### add_url_port

If set to `true`, port (use `url_port` key) will be added to the record. Defaults to `false`.

### add_url_path

If set to `true`, path (use `url_path` key) will be added to the record. Defaults to `false`.

## Installation

Add this line to your application's Gemfile:

    gem 'fluent-plugin-extract_query_params'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fluent-plugin-extract_query_params

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Copyright

### Copyright

Copyright (c) 2013- Kentaro Kuribayashi (@kentaro)

### License

Apache License, Version 2.0
