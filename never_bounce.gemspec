require './libs/never_bounce'

Gem::Specification.new do |s|
  s.name        = 'never_bounce'
  s.version     = '0.1.5'
  s.date        = '2016-02-22'
  s.summary     = 'NeverBounce API library for Ruby'
  s.description = 'NeverBounce gem with bulk jobs'
  s.authors     = ['Mike Mollick']
  s.email       = ['mike@neverbounce.com']
  s.homepage    = 'https://neverbounce.com'
  s.license     = 'MIT'
  s.files       = `git ls-files libs/*`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['libs']
  s.required_ruby_version     = '>= 1.9.3'

  s.add_dependency('httparty', '~> 0.14')

  s.add_development_dependency('rspec', '~> 3.4', '>= 3.4.0')
  s.add_development_dependency('rake', '~> 0')
end
