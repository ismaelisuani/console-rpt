class Unit < ApplicationRecord
  # The decoder names app_rpt sends in the AMI UNITID events
  DECODERS = %w[Mototrbo P25 MDC1200 DTMF CCIR EEA EIA ZVEI1 ZVEI2 ZVEI3].freeze

  normalizes :identifier, with: ->(id) { id.strip }

  validates :identifier, presence: true, uniqueness: { scope: :decoder }
  validates :decoder, inclusion: { in: DECODERS }
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def self.lookup(decoder, identifier)
    active.find_by(decoder: decoder, identifier: identifier)
  end
end
