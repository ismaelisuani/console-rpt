class Radio < ApplicationRecord
  belongs_to :server
  belongs_to :ptt_user, class_name: "User", optional: true
  belongs_to :transmitted_by_user, class_name: "User", optional: true
  has_many :radio_group_memberships, dependent: :destroy
  has_many :radio_groups, through: :radio_group_memberships
  has_many :radio_events, dependent: :nullify

  validates :name, presence: true
  validates :node, presence: true, format: { with: /\A\d+\z/ }, uniqueness: { scope: :server_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  def online?
    server.online?
  end

  # Links of the node, from the AMI LINKS event: [{ "node" => "2000", "mode" => "transceive" | "monitor" }]
  def linked_radios
    nodes = links.map { |link| link["node"] }
    Radio.where(server: server, node: nodes).index_by(&:node)
  end

  # The unit of the reception going on, when it identified itself
  def talking_unit_identified?
    receiving? && unit_identified_at.present? && receiving_since.present? &&
      unit_identified_at >= receiving_since - RadioState::UNIT_LEAD
  end

  # PTT pressed on the console this recently names the transmission
  CONSOLE_PTT_WINDOW = 5.seconds

  def console_transmitter(now = Time.current)
    ptt_user if ptt_at && ptt_at >= now - CONSOLE_PTT_WINDOW
  end

  def last_unit
    return if last_unit_identifier.blank?

    @last_unit ||= Unit.active.find_by(decoder: last_decoder, identifier: last_unit_identifier)
  end
end
