require 'benchmark/ips'

# To determine whether it's worth caching the regexs
Benchmark.ips do |x|
  x.report('New regexp') do
    'something_else=m000; secure; HttpOnly'.sub(/; [Ss]ecure/, '')
  end

  regex = /; [Ss]ecure/
  x.report('Same regexp') do
    'something_else=m000; secure; HttpOnly'.sub(regex, '')
  end
  x.compare!
end

# Whether using regexps compared to splitting the cookie into a string
# and adding ; Secure
Benchmark.ips do |x|
  cookies_without_secure = Regexp.new("(((something_else)|(_session_id))(?!.*[Ss]ecure).*)")
  x.report('replace all with regexp') do
    "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly".gsub(cookies_without_secure, '\1; Secure')
  end

  secure = /; [Ss]ecure/
  x.report('replace by splitting strings and joining with regex') do
    "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly".split("\n").map do |line|
      line.sub(secure, '\1; Secure')
    end.join("\n")
  end

  x.report('replace by splitting strings and joining with if') do
    "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly".split("\n").map do |line|
      line =~ secure ? line : line.sub(secure, '\1; Secure')
    end.join("\n")
  end

  x.compare!
end

# Whether using regexps compared to splitting the cookie into a string
# and removing ; Secure
Benchmark.ips do |x|
  secure = /; [Ss]ecure/
  cookies_with_secure = Regexp.new("(^(something_else)|(_session_id)).*[Ss]ecure")
  x.report('replace all with regexp') do
    "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly".gsub!(cookies_with_secure) { |m| m.sub!(secure, '') }
  end

  x.report('replace by splitting strings and joining, always remove with regex') do
    "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly".split("\n").map do |line|
      line.sub!(secure, '')
    end.join("\n")
  end

  x.report('replace by splitting strings and remove if text available') do
    "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly".split("\n").map do |line|
      line =~ secure ? line.sub!(secure, '\1; Secure') : line
    end.join("\n")
  end

  x.compare!
end

# Whether it's faster to have one regex to check for known cookies with Secure
# or one to check for known cookies and then another for secure
Benchmark.ips do |x|
  x.report('do it all with one regexp') do
    cookies = "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly"
    2 > cookies.scan(/^((something_else)|(_session_id)).*[Ss]ecure/).size
  end

  x.report('do with multiple passes') do
    cookies = "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly"
    secure = /; [Ss]ecure/
    if cookies.scan(/^((something_else)|(_session_id))/).size > 0
      2 > cookies.scan(secure).size
    end
  end

  x.compare!
end

# Is it faster to check whether there's any cookies missing Secure flag
# first or just try to add it, always?
Benchmark.ips do |x|
  cookies_without_secure = Regexp.new("(((something_else)|(_session_id))(?!.*[Ss]ecure).*)")
  x.report('Always remove, regex full string') do
    cookies = "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly"
    cookies.gsub(cookies_without_secure, '\1; Secure')
  end

  x.report('Always remove, string split') do
    cookies = "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly"
    cookies.split("\n").map do |cookie|
      cookie.sub(cookies_without_secure, '\1; Secure')
    end.join("\n")
  end

  x.report('Only remove if there is a matching cookie, full regexp') do
    cookies = "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly"
    missing_secure_flag = cookies.scan(cookies_without_secure).size
    if missing_secure_flag
      cookies.gsub(cookies_without_secure, '\1; Secure')
    end
  end

  x.report('Only remove if there is a matching cookie, full regexp') do
    cookies = "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly"
    missing_secure_flag = cookies.scan(cookies_without_secure).size
    if missing_secure_flag
      cookies.split("\n").map do |cookie|
        cookie.sub(cookies_without_secure, '\1; Secure')
      end.join("\n")
    end
  end

  x.compare!
end

class Middle

  def initialize(cookies, cookie_string, ssl)
    _cookies = "^((#{cookies.join(')|(')}))".freeze
    @configured_cookies = /#{_cookies}/
    @cookies_with_secure = /(#{_cookies}.*?)(; [Ss]ecure)(.*)$/
    @cookies_without_secure = /(#{_cookies}(?!.*[Ss]ecure).*)/
    @secure = /; [Ss]ecure/

    @add_secure = lambda { |cookie| "#{cookie}; Secure" }
    @remove_secure = lambda { |cookie| cookie.sub(@secure, '') }

    @cookie_string = cookie_string
    @ssl = ssl
  end

  def call
    headers = {
        'Set-Cookie' => @cookie_string.dup
    }

    if headers['Set-Cookie'] && @configured_cookies.match(headers['Set-Cookie'])

      if @ssl
        headers['Set-Cookie'].gsub!(@cookies_without_secure, '\1; Secure')
      else
        headers['Set-Cookie'].gsub!(@cookies_with_secure, '\1\3')
      end
    end
  end

  def call_without_if
    headers = {
        'Set-Cookie' => @cookie_string.dup
    }

    if headers['Set-Cookie']
      if @ssl
        headers['Set-Cookie'].gsub!(@cookies_without_secure, '\1; Secure')
      else
        headers['Set-Cookie'].gsub!(@cookies_with_secure, '\1\3')
      end
    end
  end

  def call_old
    headers = {
        'Set-Cookie' => @cookie_string.dup
    }

    if headers['Set-Cookie']

      if @ssl
        # headers['Set-Cookie'].gsub!(@cookies_without_secure, '\1; Secure')
        _modify_secure_flag(headers, true, ->(cookie) { cookie.gsub!(@cookies_without_secure, '\1; Secure') })
      else
        # headers['Set-Cookie'].gsub!(@cookies_with_secure, '\1\3')
        _modify_secure_flag(headers, false, ->(cookie) { cookie.gsub!(@cookies_with_secure, '\1\3') })
      end
    end
  end

  def _modify_secure_flag(headers, is_secure, replacement)
    headers['Set-Cookie'] = headers['Set-Cookie'].split("\n").map do |cookie|
      if cookie =~ @configured_cookies && !!(cookie =~ @secure) == is_secure
        replacement.call(cookie)
      else
        cookie
      end
    end.join("\n")
  end
end

Benchmark.ips do |x|
  some_matching = Middle.new(['session_id'], "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly", true)
  x.report('mixed cookie setting, with if') { some_matching.call }
  x.report('mixed cookie setting, call old') { some_matching.call_old }

  all_matching = Middle.new(['session_id', 'something_else', 'here_to_mess_up'],
                            "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly", true)
  x.report('all cookies matching, with if') { all_matching.call }
  x.report('all cookies matching, call old') { all_matching.call_old }

  no_matching = Middle.new(['something_elsez'],
                           "something_else=m000; secure; HttpOnly\n_session_id=meoeo; HttpOnly\nhere_to_mess_up=nope; HttpOnly", true)
  # x.report('no matching, with if') { no_matching.call }

  x.report('mixed cookie setting, no if') { some_matching.call_without_if }
  x.report('all cookies matching, no if') { all_matching.call_without_if }
  # x.report('no matching, no if') { no_matching.call_without_if }

  x.compare!
end
