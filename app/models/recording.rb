class Recording < ApplicationRecord
  include Recording::ArchiveFile, Recording::Audio, Recording::Filtering

  DIRECTIONS = %w[rx tx].freeze

  belongs_to :server
  belongs_to :radio, optional: true

  validates :direction, inclusion: { in: DIRECTIONS }

  scope :recent, -> { order(started_at: :desc) }

  def rx?
    direction == "rx"
  end

  def unit
    Unit.lookup(decoder, unit_identifier) if unit_identifier.present?
  end
end
