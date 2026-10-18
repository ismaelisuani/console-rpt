class ContactFavorite < ApplicationRecord
  belongs_to :user
  belongs_to :contact

  validates :contact_id, uniqueness: { scope: :user_id }
end
