class Server < ApplicationRecord
  encrypts :ami_password

  has_many :radios, dependent: :restrict_with_error
  has_many :radio_events, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :host, :ami_username, :ami_password, :archive_path, presence: true
  validates :ami_port, :ssh_port, numericality: { only_integer: true, in: 1..65_535 }
  validates :local, uniqueness: true, if: :local?
  validates :webrtc_url, format: { with: %r{\Awss?://\S+\z} }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
