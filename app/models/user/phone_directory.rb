# What the user's phone shows to call with one click: their favorite contacts
# and the other console users' extensions
module User::PhoneDirectory
  extend ActiveSupport::Concern

  included do
    has_many :contact_favorites, dependent: :destroy
    has_many :favorite_contacts, through: :contact_favorites, source: :contact
  end

  def colleagues_with_phone
    User.active.where.not(id: id).where.not(sip_extension: nil).includes(:role).ordered.select(&:phone_account?)
  end
end
