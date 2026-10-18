module ContactsHelper
  def favorite_toggle(contact)
    favorite = contact.favorite_of?(Current.user)
    button_to (favorite ? "★" : "☆"), contact_favorite_path(contact), method: (favorite ? :delete : :post),
      class: class_names("cursor-pointer text-lg leading-none", favorite ? "text-warn-ink" : "text-faint hover:text-warn-ink"),
      title: favorite ? t("contacts.index.unfavorite") : t("contacts.index.favorite"), form: { class: "flex" }
  end
end
