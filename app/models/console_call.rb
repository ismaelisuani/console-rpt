require "digest"

# What the browser needs to call a radio over WebRTC: the server's WebSocket,
# the console SIP account and a token that the server's dialplan checks
# (extensions_console.conf of asterisk-rpt): it expires in a minute and fixes
# the node, the user and the level (operate: phone mode with PTT; listen:
# monitor only).
class ConsoleCall
  TTL = 60.seconds

  attr_reader :radio, :user

  def initialize(radio, user)
    @radio = radio
    @user = user
  end

  def level
    user.can_transmit_on?(radio) ? "operate" : "listen"
  end

  def token(now: Time.current)
    expires = (now + TTL).to_i
    signature = Digest::SHA1.hexdigest("#{server.console_secret}:#{radio.node}:#{expires}:#{level}:#{user.id}")
    "#{expires}:#{level}:#{user.id}:#{signature}"
  end

  def as_json(*)
    {
      ws: server.webrtc_url,
      host: server.webrtc_host,
      username: server.sip_username,
      password: server.sip_password,
      uri: "sip:#{radio.node}@#{server.webrtc_host}",
      token: token,
      level: level
    }
  end

  private
    def server
      radio.server
    end
end
