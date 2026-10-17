class RadioGroupAccess < ApplicationRecord
  LEVELS = %w[operate listen].freeze

  belongs_to :user
  belongs_to :radio_group

  validates :level, inclusion: { in: LEVELS }
  validates :radio_group_id, uniqueness: { scope: :user_id }
end
