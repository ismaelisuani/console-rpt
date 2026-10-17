class Server < ApplicationRecord
  include Server::Ami, Server::ConsoleCredentials, Server::Status

  has_many :radios, dependent: :restrict_with_error
  has_many :radio_events, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :host, :archive_path, presence: true
  validates :local, uniqueness: true, if: :local?

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
