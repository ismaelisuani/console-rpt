class Contact < ApplicationRecord
  include Contact::Favorites

  NUMBER_FORMAT = /\A[0-9*#+]{1,32}\z/

  normalizes :number, with: ->(number) { number.gsub(/[\s\-().]/, "") }

  validates :name, presence: true
  validates :number, presence: true, format: { with: NUMBER_FORMAT }

  scope :ordered, -> { order(:name) }

  def self.search(text)
    return all if text.blank?

    pattern = "%#{sanitize_sql_like(text.strip)}%"
    where("name ILIKE :q OR number ILIKE :q OR organization ILIKE :q", q: pattern)
  end
end
