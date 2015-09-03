module Rack
  class PotentiallySecureCookies
    VERSION = '0.9.0'

    def initialize(app, cookies)
      @app = app
      @cookies = "(#{cookies.join('|')})"
    end

    def call(env)
      status, headers, body = @app.call(env)

      if headers['Set-Cookie'] && headers['Set-Cookie'] =~ /^#{@cookies}/
        request = Rack::Request.new(env)
        has_secure_flag = (headers['Set-Cookie'] =~ /^#{@cookies}.*?[Ss]ecure/)

        if request.ssl? && !has_secure_flag
          headers['Set-Cookie'].gsub!(/^(#{@cookies}.*)$/, '\1; Secure')
        elsif has_secure_flag
          headers['Set-Cookie'].gsub!(/^(#{@cookies}.*)$/) { |m| m.sub!(/; [Ss]ecure/, '') }
        end
      end

      [status, headers, body]
    end
  end
end
