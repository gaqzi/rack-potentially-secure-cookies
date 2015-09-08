require_relative '../spec_helper'
require_relative '../../lib/rack/potentially_secure_cookies'


describe Rack::PotentiallySecureCookies do
  let(:app_headers) { Hash.new }
  let(:cookies_to_force_ssl) { ['_session_id'] }
  let(:app) { mock_app(app_headers['Set-Cookie'], cookies_to_force_ssl) }
  let(:response) { get '/', nil, {'HTTP_X_FORWARDED_PROTO' => https ? 'https' : 'http'} }

  context 'request is HTTPS' do
    let(:https) { true }
    let!(:cookie_session) { Rack::Utils.set_cookie_header!(app_headers, '_session_id', {value: '1', http_only: true}) }

    it 'ensures that the secure flag is set' do
      expect(response.header['Set-Cookie']).to include('; Secure')
    end

    context 'there are multiple cookies set' do
      let!(:cookie_something_else) { Rack::Utils.set_cookie_header!(app_headers, 'something_else', {value: 'm000', http_only: true}) }

      it 'only sets the secure flag for the configured cookie' do
        expect(response.header['Set-Cookie']).to match(/^(#{cookies_to_force_ssl.join('|')}).*(; [Ss]ecure).*$/)
      end

      context 'all cookies are configured' do
        let(:cookies_to_force_ssl) { ['_session_id', 'something_else'] }

        it 'sets the secure flag for all' do
          expect(response.header['Set-Cookie'].scan(/[Ss]ecure/).size).to eq(2)
        end
      end

      context 'one of the cookies have the secure flag set' do
        let!(:cookie_something_else) { Rack::Utils.set_cookie_header!(app_headers, 'something_else', {value: 'm000', http_only: true, secure: true}) }
        let(:cookies_to_force_ssl) { ['_session_id', 'something_else'] }

        it 'sets the secure flag for all' do
          expect(response.header['Set-Cookie'].scan(/[Ss]ecure/).size).to eq(cookies_to_force_ssl.size)
        end
      end

      context 'there is a cookie that should not have the secure flag set, and a configured cookie is missing' do
        let(:cookies_to_force_ssl) { ['_session_id', 'something_elsez'] }

        it 'sets the secure flag for the configured cookie' do
          puts response.header['Set-Cookie']
          expect(response.header['Set-Cookie'].scan(/[Ss]ecure/).size).to eq(1)
        end
      end
    end
  end

  context 'request is HTTP' do
    let(:https) { false }
    let(:secure_flag) { false }
    let!(:cookie_session) { Rack::Utils.set_cookie_header!(app_headers, '_session_id', {value: '1', http_only: true, secure: secure_flag}) }

    it 'does not have the secure flag set' do
      expect(response['Set-Cookie']).to_not match /[Ss]ecure/
    end

    context 'cookie had the secure flag set' do
      let(:secure_flag) { true }

      it 'strips the secure flag' do
        expect(response['Set-Cookie']).to_not match /[Ss]ecure/
      end

      context 'there are multiple cookies set' do
        let!(:cookie_something_else) { Rack::Utils.set_cookie_header!(app_headers, 'something_else', {value: 'm000', http_only: true, secure: secure_flag}) }
        let(:cookies_to_force_ssl) { ['something_else'] }

        it 'strips the secure flag for the configured cookie' do
          expect(response.header['Set-Cookie']).to_not match(/^(#{cookies_to_force_ssl.join('|')}).*(; [Ss]ecure).*$/)
        end

        context 'all cookies are configured' do
          let(:cookies_to_force_ssl) { ['_session_id', 'something_else'] }

          it 'strips the secure flag for all' do
            expect(response.header['Set-Cookie'].scan(/[Ss]ecure/).size).to eq(0)
          end
        end
      end
    end
  end
end
