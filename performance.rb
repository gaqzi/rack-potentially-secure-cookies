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
