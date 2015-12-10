$:.push File.expand_path('../lib', __FILE__)

require 'rack/potentially_secure_cookies'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'rack-potentially-secure-cookies'
  s.version     = Rack::PotentiallySecureCookies::VERSION
  s.authors     = ['Björn Andersson']
  s.email       = ['ba@sanitarium.se']
  s.homepage    = 'https://github.com/gaqzi/rack-potentially-secure-cookies'
  s.summary     = 'Force the secure bit of a cookie depending on whether your connection is secure'
  s.license     = 'MIT'

  s.files = Dir['lib/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'rack'
end
