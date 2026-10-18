require "test_helper"

class Radio::ConsoleCallsTest < ActiveSupport::TestCase
  test "the token is what the server's dialplan checks" do
    now = Time.zone.parse("2026-10-17 12:00:00")
    expires = (now + Server::ConsoleCredentials::CALL_TOKEN_TTL).to_i
    user_id = users(:dispatcher).id
    signature = Digest::SHA1.hexdigest("console-secret:1999:#{expires}:operate:#{user_id}")

    token = radios(:base).server.console_token(subject: "1999", level: radios(:base).console_call_level(users(:dispatcher)), user: users(:dispatcher), now: now)
    assert_equal "#{expires}:operate:#{user_id}:#{signature}", token
  end

  test "listen level without transmit access" do
    assert_equal "listen", radios(:base).console_call_level(users(:listener))
  end

  test "what the browser gets" do
    call = radios(:base).console_call(users(:dispatcher))
    assert_equal "sip:1999@radio.example.com", call[:uri]
    assert_equal "wss://radio.example.com:8089/ws", call[:ws]
    assert_equal "webconsole", call[:username]
  end
end
