class User < ApplicationRecord
  include User::Authentication, User::Permissions, User::RadioAccess, User::SelfProtection, User::DispatchLayouts, User::Preferences

  has_many :sessions, dependent: :destroy
  belongs_to :role
  has_many :radio_group_accesses, dependent: :destroy, autosave: true
  has_many :radio_groups, through: :radio_group_accesses

  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
