# What the server's Asterisk configuration needs for the console's WebRTC
# calls (pjsip_console.conf and extensions_console.conf of asterisk-rpt)
require "digest"

module Server::ConsoleCredentials
  extend ActiveSupport::Concern

  CALL_TOKEN_TTL = 60.seconds

  included do
    encrypts :sip_password, :console_secret

    before_validation :generate_console_credentials, on: :create
    validates :webrtc_url, format: { with: %r{\Awss?://\S+\z} }, allow_blank: true
  end

  def sip_password=(value)
    super if value.present?
  end

  # Token for a call from the console, checked by the server's dialplan
  # (extensions_console.conf): SHA1("secret:subject:expires:level:user")
  # with subject the node (radios) or the number (phone)
  def console_token(subject:, level:, user:, now: Time.current)
    expires = (now + CALL_TOKEN_TTL).to_i
    signature = Digest::SHA1.hexdigest("#{console_secret}:#{subject}:#{expires}:#{level}:#{user.id}")
    "#{expires}:#{level}:#{user.id}:#{signature}"
  end

  # What the browser needs to place a call to subject (a node or a number)
  def console_call(subject:, level:, user:)
    {
      ws: webrtc_url,
      host: webrtc_host,
      username: sip_username,
      password: sip_password,
      uri: "sip:#{subject}@#{webrtc_host}",
      token: console_token(subject: subject, level: level, user: user),
      level: level
    }
  end

  def webrtc?
    webrtc_url.present? && sip_password.present? && console_secret.present?
  end

  def webrtc_host
    URI.parse(webrtc_url).host if webrtc_url.present?
  end

  private
    def generate_console_credentials
      self.sip_password = SecureRandom.hex(16) if sip_password.blank?
      self.console_secret = SecureRandom.hex(24) if console_secret.blank?
    end
end
