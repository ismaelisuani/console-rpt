class Role < ApplicationRecord
  PERMISSIONS = %w[
    view_dispatch listen transmit connect
    view_recordings manage_units manage_radios manage_users
  ].freeze

  has_many :users, dependent: :restrict_with_error

  normalizes :permissions, with: ->(list) { PERMISSIONS & Array(list).map(&:to_s) }

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def grants?(permission)
    permissions.include?(permission.to_s)
  end
end
