# Users mark contacts as favorites: they show in their phone, one click away
module Contact::Favorites
  extend ActiveSupport::Concern

  included do
    has_many :contact_favorites, dependent: :destroy
  end

  def favorite_of?(user)
    contact_favorites.any? { |favorite| favorite.user_id == user.id }
  end
end
