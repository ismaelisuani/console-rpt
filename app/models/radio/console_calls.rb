require "digest"

# What the browser needs to call the radio over WebRTC: the server's
# WebSocket, the console SIP account and a token that the server's dialplan
# checks (extensions_console.conf of asterisk-rpt). The token expires in a
# minute and fixes the node, the user and the level: operate (phone mode with
# PTT) or listen (monitor only).
module Radio::ConsoleCalls
  extend ActiveSupport::Concern

  CALL_TOKEN_TTL = 60.seconds

  def console_call_level(user)
    user.can_transmit_on?(self) ? "operate" : "listen"
  end

  def console_call_token(user, now: Time.current)
    level = console_call_level(user)
    expires = (now + CALL_TOKEN_TTL).to_i
    signature = Digest::SHA1.hexdigest("#{server.console_secret}:#{node}:#{expires}:#{level}:#{user.id}")
    "#{expires}:#{level}:#{user.id}:#{signature}"
  end

  def console_call(user)
    {
      ws: server.webrtc_url,
      host: server.webrtc_host,
      username: server.sip_username,
      password: server.sip_password,
      uri: "sip:#{node}@#{server.webrtc_host}",
      token: console_call_token(user),
      level: console_call_level(user)
    }
  end
end
