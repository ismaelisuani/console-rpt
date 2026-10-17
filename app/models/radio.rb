class Radio < ApplicationRecord
  include Radio::LiveState, Radio::Links, Radio::ConsoleCalls, Radio::Broadcasting

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
end
