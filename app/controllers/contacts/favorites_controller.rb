# The current user marks or unmarks a contact as a favorite
class Contacts::FavoritesController < ApplicationController
  require_permission :phone
  before_action { @contact = Contact.find(params.expect(:contact_id)) }

  def create
    Current.user.contact_favorites.find_or_create_by!(contact: @contact)
    redirect_back_or_to contacts_path
  end

  def destroy
    Current.user.contact_favorites.where(contact: @contact).destroy_all
    redirect_back_or_to contacts_path
  end
end
