module Localization
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale
  end

  private
    def switch_locale(&action)
      I18n.with_locale(current_locale, &action)
    end

    def current_locale
      Current.user&.locale.presence_in(available_locales) ||
        params[:locale].presence_in(available_locales) ||
        browser_locale ||
        I18n.default_locale
    end

    def browser_locale
      request.env["HTTP_ACCEPT_LANGUAGE"].to_s.split(",").each do |entry|
        tag = entry.split(";").first.strip
        found = available_locales.find { |locale| locale.casecmp?(tag) } ||
          available_locales.find { |locale| locale.split("-").first.casecmp?(tag.split("-").first) }
        return found if found
      end
      nil
    end

    def available_locales
      I18n.available_locales.map(&:to_s)
    end
end
