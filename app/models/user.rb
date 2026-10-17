class User < ApplicationRecord
  include User::Permissions, User::RadioAccess, User::SelfProtection

  has_secure_password
  has_many :sessions, dependent: :destroy
  belongs_to :role
  has_many :radio_group_accesses, dependent: :destroy, autosave: true
  has_many :radio_groups, through: :radio_group_accesses

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validates :name, presence: true
  validates :email_address, presence: true, uniqueness: true
  validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
