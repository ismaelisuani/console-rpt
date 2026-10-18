# The user's phone extension: a PJSIP endpoint on the phone server, written
# by the console (Server::UserExtensions). Assigned automatically from a range
# (CONSOLE_EXTENSIONS, 200-299 by default); an administrator can change it.
module User::SipAccount
  extend ActiveSupport::Concern

  EXTENSION_FORMAT = /\A\d{2,6}\z/
  PROVISIONED_ATTRIBUTES = %w[sip_extension sip_password name active role_id].freeze

  included do
    encrypts :sip_password

    normalizes :sip_extension, with: ->(extension) { extension.strip.presence }

    before_validation :assign_sip_account, on: :create
    validates :sip_extension, format: { with: EXTENSION_FORMAT }, uniqueness: true, allow_nil: true

    after_commit :provision_extensions, if: -> { destroyed? || (saved_changes.keys & PROVISIONED_ATTRIBUTES).any? }
  end

  class_methods do
    def extension_range
      first, last = ENV.fetch("CONSOLE_EXTENSIONS", "200-299").split("-").map(&:to_i)
      first..last
    end

    def next_free_extension
      taken = where.not(sip_extension: nil).pluck(:sip_extension).to_set
      extension_range.find { |number| !taken.include?(number.to_s) }&.to_s
    end
  end

  # Users who may use the phone get an endpoint
  def phone_account?
    active? && sip_extension.present? && sip_password.present? && can?(:phone)
  end

  private
    def assign_sip_account
      self.sip_extension = self.class.next_free_extension if sip_extension.blank?
      self.sip_password = SecureRandom.hex(16) if sip_password.blank?
    end

    def provision_extensions
      Server.provision_user_extensions_later
    end
end
