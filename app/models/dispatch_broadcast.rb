# Turbo Stream updates of the dispatch screen. The rendered HTML is translated,
# so there is one stream per radio and locale.
module DispatchBroadcast
  extend self

  def radio_state(radio)
    each_locale do |locale|
      Turbo::StreamsChannel.broadcast_replace_to(stream(radio, locale), target: ActionView::RecordIdentifier.dom_id(radio, :state),
        partial: "dispatch/radio_state", locals: { radio: radio })
    end
  end

  def activity(event)
    return unless event.radio

    each_locale do |locale|
      Turbo::StreamsChannel.broadcast_prepend_to(stream(event.radio, locale), target: "activity",
        partial: "dispatch/activity_entry", locals: { event: event })
    end
  end

  def activity_replaced(event)
    each_locale do |locale|
      Turbo::StreamsChannel.broadcast_replace_to(stream(event.radio, locale), target: ActionView::RecordIdentifier.dom_id(event),
        partial: "dispatch/activity_entry", locals: { event: event })
    end
  end

  def servers_status
    each_locale do |locale|
      Turbo::StreamsChannel.broadcast_replace_to([ :servers_status, locale ], target: "servers_status", partial: "layouts/servers_status")
    end
  end

  def stream(radio, locale = I18n.locale)
    [ radio, locale.to_s ]
  end

  private
    def each_locale
      I18n.available_locales.each { |locale| I18n.with_locale(locale) { yield locale } }
    end
end
