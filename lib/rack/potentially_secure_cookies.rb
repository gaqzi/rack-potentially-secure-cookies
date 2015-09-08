module Rack
  class PotentiallySecureCookies
    VERSION = '0.9.0'

    def initialize(app, cookies)
      @app = app
      @configured_cookies = cookies.size
      @cookies = "^((#{cookies.join(')|(')}))".freeze
      @cookies_regex = /#{@cookies}/
      @cookies_with_secure = /#{@cookies}.*[Ss]ecure/
      @cookies_without_secure = /(#{@cookies}(?!.*[Ss]ecure).*)/
      @secure = /; [Ss]ecure/
    end

    def call(env)
      status, headers, body = @app.call(env)

      if headers['Set-Cookie'] && @cookies_regex.match(headers['Set-Cookie'])
        request = Rack::Request.new(env)
        missing_secure_flag = headers['Set-Cookie'].scan(@cookies_without_secure).size

        if request.ssl?
          if missing_secure_flag > 0
            headers['Set-Cookie'] = headers['Set-Cookie'].split("\n").map do |cookie|
              cookie =~ @cookies_with_secure ? cookie : "#{cookie}; Secure"
            end.join("\n")
          end
        else
          if @configured_cookies > missing_secure_flag
            headers['Set-Cookie'].gsub!(@cookies_with_secure) { |m| m.sub!(@secure, '') }
          end
        end
      end

      [status, headers, body]
    end
  end
end
