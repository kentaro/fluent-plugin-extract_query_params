Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-extract_query_params'
  gem.version       = '0.1.1'
  gem.authors       = ['Kentaro Kuribayashi']
  gem.email         = ['kentarok@gmail.com']
  gem.homepage      = 'http://github.com/kentaro/fluent-plugin-extract_query_params'
  gem.description   = %q{Fluentd plugin to extract key/values from URL query parameters.}
  gem.summary       = %q{Fluentd plugin to extract key/values from URL query parameters}
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  if defined?(RUBY_VERSION) && RUBY_VERSION > '2.2'
    gem.add_development_dependency "test-unit", '~> 3'
  end

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'appraisal'
  gem.add_runtime_dependency     'fluentd', ['>= 0.14.8', '< 2']
end
