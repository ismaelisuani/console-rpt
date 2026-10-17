# Turbo Stream broadcasts of translated HTML: one stream per locale, so every
# screen gets the update in its user's language
module LocalizedBroadcasts
  extend ActiveSupport::Concern

  class_methods do
    def each_broadcast_locale
      I18n.available_locales.each { |locale| I18n.with_locale(locale) { yield locale.to_s } }
    end
  end

  def each_broadcast_locale(&)
    self.class.each_broadcast_locale(&)
  end
end
