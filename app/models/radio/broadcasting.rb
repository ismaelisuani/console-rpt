# The radio's tile state on the dispatch screens: one stream per radio and locale
module Radio::Broadcasting
  extend ActiveSupport::Concern
  include LocalizedBroadcasts

  def broadcast_stream(locale = I18n.locale)
    [ self, locale.to_s ]
  end

  def broadcast_state
    each_broadcast_locale do |locale|
      Turbo::StreamsChannel.broadcast_replace_to(broadcast_stream(locale), target: ActionView::RecordIdentifier.dom_id(self, :state),
        partial: "dispatch/radio_state", locals: { radio: self })
    end
  end
end
