class Unit < ApplicationRecord
  include Unit::Decoders, Unit::Importable

  normalizes :identifier, with: ->(id) { id.strip }

  validates :identifier, presence: true, uniqueness: { scope: :decoder }
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }
end
