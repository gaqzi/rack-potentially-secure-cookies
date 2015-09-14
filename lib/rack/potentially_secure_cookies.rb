module Rack
  class PotentiallySecureCookies
    VERSION = '0.9.0'

    def initialize(app, cookies)
      @app = app

      # All in the name to make this as fast as possible anything that
      # could be used in multiple requests have been defined here.
      _cookies = "^((#{cookies.join(')|(')}))".freeze
      @configured_cookies = /#{_cookies}/
      @cookies_with_secure = /(#{_cookies}.*?)(; [Ss]ecure)(.*)$/
      @cookies_without_secure = /(#{_cookies}(?!.*[Ss]ecure).*)/
      @secure = /; [Ss]ecure/
    end

    def call(env)
      status, headers, body = @app.call(env)

      if headers['Set-Cookie'] && @configured_cookies.match(headers['Set-Cookie'])
        request = Rack::Request.new(env)

        if request.ssl?
          headers['Set-Cookie'].gsub!(@cookies_without_secure, '\1; Secure')
        else
          headers['Set-Cookie'].gsub!(@cookies_with_secure, '\1\3')
        end
      end

      [status, headers, body]
    end
  end
end
