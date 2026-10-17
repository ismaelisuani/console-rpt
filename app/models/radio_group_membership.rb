class RadioGroupMembership < ApplicationRecord
  belongs_to :radio_group
  belongs_to :radio

  validates :radio_id, uniqueness: { scope: :radio_group_id }
end
