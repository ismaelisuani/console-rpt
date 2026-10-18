# What each user picks for themselves: language and light or dark theme
module User::Preferences
  extend ActiveSupport::Concern

  THEMES = %w[dark light].freeze

  included do
    validates :locale, inclusion: { in: ->(_) { I18n.available_locales.map(&:to_s) } }
    validates :theme, inclusion: { in: THEMES }
  end
end
