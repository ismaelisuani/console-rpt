class User < ApplicationRecord
  include User::Authentication, User::Permissions, User::RadioAccess, User::SelfProtection, User::DispatchLayouts

  has_many :sessions, dependent: :destroy
  belongs_to :role
  has_many :radio_group_accesses, dependent: :destroy, autosave: true
  has_many :radio_groups, through: :radio_group_accesses

  validates :name, presence: true
  validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
