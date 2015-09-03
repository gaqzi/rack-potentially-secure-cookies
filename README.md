# Rack::PotentiallySecureCookie

This is a Rack middleware for one very specific purpose;

You have a site running on a server that can be accessed through both HTTP and
HTTPS. Whichever method the user accesses the site she'll never change. So if
you access the site the first time through HTTPS you will continue to do so.

Because security we needed a way to ensure that the cookie flag `Secure` was
being set whenever our users accesses the site through HTTPS, and to ensure it
was *not* set when accessing through HTTP as the users couldn't login then.

An example of this is:

* The site is running on a secured server deep in the middle of a datacenter
* This site serves the public internet and because of this there's SSL
  termination in front of the site
* The same site is also being used internally at the company, under a split-view
  setup and these users are not able to go through the SSL termination
* Since it would be wasteful to run the server with multiple instances of the
  app only to configure the secure cookie setting something to dynamically set
  this needed to be done

## Installation and configuration

This is available as a gem so just add to your `Gemfile`:

```ruby
gem 'rack-potentially-secure-cookies'
```

In your `environment.rb` (or maybe `environments/production.rb`) add the middleware:

```ruby
config.middleware.insert_before(ActionDispatch::Cookies,
                                Rack::PotentiallySecureCookies,
                                ['_session_id'])
```

The last argument is an array of cookies to force this configuration on.

## License

MIT License
