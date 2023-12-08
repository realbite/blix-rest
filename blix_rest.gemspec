require 'rake'
require './lib/blix/rest/version'

Gem::Specification.new do |s|
  s.name = 'blix-rest'
  s.description = %Q[Rack based framework focused on building JSON REST web services.
Concentrates on making the basics very easy to write and fast to execute.
Fully extensible through RACK middleware and your own code]
  s.summary = 'Framework for HTTP REST services'
  s.version = Blix::Rest::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Clive Andrews']
  s.license = 'MIT'
  s.email = ['gems@realitybites.eu']
  s.homepage = 'https://github.com/realbite/blix-rest'


  s.add_dependency('httpclient')
  s.add_dependency('multi_json')
  s.add_dependency('rack', ">=2.0.0")

  s.add_development_dependency('rspec')
  s.add_development_dependency('pry')
  s.files = FileList['lib/blix/rest/**/*.rb' ].to_a
  s.files << 'lib/blix/rest.rb'
  s.files << 'lib/blix/utils.rb'
  s.files +=  FileList['lib/blix/utils/**/*.rb' ].to_a
  s.files << 'LICENSE'
  s.files << 'README.md'

  s.extra_rdoc_files = ['README.md','LICENSE']
  s.require_paths = ['lib']
end
