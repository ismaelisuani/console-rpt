class RadioGroup < ApplicationRecord
  has_many :radio_group_memberships, -> { order(:position) }, dependent: :destroy
  has_many :radios, through: :radio_group_memberships
  has_many :radio_group_accesses, dependent: :destroy
  # Each user's arrangement of the group's screen goes with it
  has_many :dispatch_layouts, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  scope :ordered, -> { order(:position, :name) }
end
