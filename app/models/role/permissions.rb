module Role::Permissions
  extend ActiveSupport::Concern

  ALL = %w[
    view_dispatch listen transmit connect phone
    view_recordings manage_units manage_radios manage_users
  ].freeze

  included do
    normalizes :permissions, with: ->(list) { ALL & Array(list).map(&:to_s) }
    # Nobody can take away their own user administration
    validate :keeps_user_administration, if: -> { Current.user&.role_id == id && persisted? }
    # who has the phone (an extension) may have changed
    after_commit -> { Server.provision_user_extensions_later }, if: -> { saved_change_to_permissions? }
  end

  def grants?(permission)
    permissions.include?(permission.to_s)
  end

  private
    def keeps_user_administration
      errors.add(:permissions, :keeps_admin) unless grants?(:manage_users)
    end
end
