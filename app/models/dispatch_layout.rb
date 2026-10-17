class DispatchLayout < ApplicationRecord
  include DispatchLayout::Arrangement

  belongs_to :user
  belongs_to :radio_group, optional: true

  validates :radio_group_id, uniqueness: { scope: :user_id }
end
