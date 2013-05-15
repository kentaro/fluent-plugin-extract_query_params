# fluent-plugin-extract_query_params

## Component

### ExtractQueryParamsOutput

Fluentd plugin to extract key/values from URL query parameters.

## Synopsis

Imagin you have a config as below:

```
<match test.**>
  type extract_query_params

  key            url
  add_tag_prefix extracted.
  only           foo, baz
</match>
```

And you feed such a value into fluentd:

```
"test" => {
  "url" => "http://example.com/?foo=bar&baz=qux&hoge=fuga"
}
```

Then you'll get re-emmited tag/record-s below:

```
"extracted.test" => {
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
