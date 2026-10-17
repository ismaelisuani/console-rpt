require "test_helper"

class ConsoleCallTest < ActiveSupport::TestCase
  test "the token is what the server's dialplan checks" do
    now = Time.zone.parse("2026-10-17 12:00:00")
    call = ConsoleCall.new(radios(:base), users(:dispatcher))
    expires = (now + ConsoleCall::TTL).to_i
    user_id = users(:dispatcher).id
    signature = Digest::SHA1.hexdigest("console-secret:1999:#{expires}:operate:#{user_id}")

    assert_equal "#{expires}:operate:#{user_id}:#{signature}", call.token(now: now)
  end

  test "listen level without transmit access" do
    assert_equal "listen", ConsoleCall.new(radios(:base), users(:listener)).level
  end

  test "what the browser gets" do
    json = ConsoleCall.new(radios(:base), users(:dispatcher)).as_json
    assert_equal "sip:1999@radio.example.com", json[:uri]
    assert_equal "wss://radio.example.com:8089/ws", json[:ws]
    assert_equal "webconsole", json[:username]
  end

  test "servers get console credentials when created" do
    server = Server.create!(name: "New", host: "10.0.0.2", ami_username: "console", ami_password: "x")
    assert_equal 32, server.sip_password.size
    assert_equal 48, server.console_secret.size
  end
end
