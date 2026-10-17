class Role < ApplicationRecord
  include Role::Permissions

  has_many :users, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { case_sensitive: false }
end
