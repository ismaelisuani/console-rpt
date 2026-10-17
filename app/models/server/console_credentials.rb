# What the server's Asterisk configuration needs for the console's WebRTC
# calls (pjsip_console.conf and extensions_console.conf of asterisk-rpt)
module Server::ConsoleCredentials
  extend ActiveSupport::Concern

  included do
    encrypts :sip_password, :console_secret

    before_validation :generate_console_credentials, on: :create
    validates :webrtc_url, format: { with: %r{\Awss?://\S+\z} }, allow_blank: true
  end

  def sip_password=(value)
    super if value.present?
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
