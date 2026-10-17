class Server < ApplicationRecord
  encrypts :ami_password, :sip_password, :console_secret

  has_many :radios, dependent: :restrict_with_error
  has_many :radio_events, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :host, :ami_username, :ami_password, :archive_path, presence: true
  validates :ami_port, :ssh_port, numericality: { only_integer: true, in: 1..65_535 }
  validates :local, uniqueness: true, if: :local?
  validates :webrtc_url, format: { with: %r{\Awss?://\S+\z} }, allow_blank: true

  before_validation :generate_console_credentials, on: :create

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def webrtc?
    webrtc_url.present? && sip_password.present? && console_secret.present?
  end

  def webrtc_host
    URI.parse(webrtc_url).host if webrtc_url.present?
  end

  private
    # The values that the server's Asterisk configuration needs
    # (pjsip_console.conf and extensions_console.conf of asterisk-rpt)
    def generate_console_credentials
      self.sip_password = SecureRandom.hex(16) if sip_password.blank?
      self.console_secret = SecureRandom.hex(24) if console_secret.blank?
    end
end
