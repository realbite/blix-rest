require 'rake'
require './lib/blix/rest/version'

Gem::Specification.new do |s|
  s.name = 'blix_rest'
  s.version = Blix::Rest::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Clive Andrews']
  s.email = ['gems@realitybites.eu']
  s.homepage = 'http://www.realitybites.eu/'
  s.summary = 'Framework for HTTP REST services'
  s.description = s.summary
  s.add_dependency('httpclient', '>= 0.0.0')
  s.add_dependency('multi_json', '>= 0.0.0')
  s.add_dependency('rack', '>= 0.0.0')
  
  s.add_development_dependency('rspec', '>= 0.0.0')
 
  s.files = FileList['lib/blix/rest/**/*.rb'].to_a
  s.files << 'lib/blix/rest.rb'

  #s.extra_rdoc_files = ['README']
  s.require_paths = ['lib']
end
