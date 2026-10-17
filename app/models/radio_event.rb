class RadioEvent < ApplicationRecord
  include RadioEvent::Broadcasting

  KINDS = %w[
    receive_start unit_identified transmit_start
    linked unlinked server_online server_offline
  ].freeze

  belongs_to :radio, optional: true
  belongs_to :server, optional: true
  belongs_to :user, optional: true

  validates :kind, inclusion: { in: KINDS }

  before_validation { self.occurred_at ||= Time.current }

  scope :recent, -> { order(occurred_at: :desc) }

  def unit
    Unit.lookup(decoder, unit_identifier) if unit_identifier.present?
  end
end
