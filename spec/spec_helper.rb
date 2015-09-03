require 'rubygems'
require 'bundler/setup'
require 'rspec'
require 'rack'
require 'rack/test'

RSpec.configure do |config|
  config.mock_with :rspec
  config.include Rack::Test::Methods
end


def mock_app(cookies = nil, middleware_options = [], https: true)
  main_app = lambda { |env|
    headers = {'Content-Type' => 'text/html'}
    headers['Set-Cookie'] = cookies if cookies
    [200, headers, ['Hello world!']]
  }

  builder = Rack::Builder.new
  middleware_options = [middleware_options] unless middleware_options.is_a?(Array)
  builder.use Rack::PotentiallySecureCookies, middleware_options
  builder.run main_app
  builder.to_app
end
