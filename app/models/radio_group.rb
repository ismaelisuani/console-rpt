class RadioGroup < ApplicationRecord
  has_many :radio_group_memberships, -> { order(:position) }, dependent: :destroy
  has_many :radios, through: :radio_group_memberships
  has_many :radio_group_accesses, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:position, :name) }
end
