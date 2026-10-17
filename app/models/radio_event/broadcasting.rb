# New activity goes on top of the dispatch screens' activity log; a reception
# that identifies itself later is replaced in place
module RadioEvent::Broadcasting
  extend ActiveSupport::Concern
  include LocalizedBroadcasts

  included do
    after_create_commit :broadcast_created, if: :radio
    after_update_commit :broadcast_updated, if: :radio
  end

  private
    def broadcast_created
      each_broadcast_locale do |locale|
        Turbo::StreamsChannel.broadcast_prepend_to(radio.broadcast_stream(locale), target: "activity",
          partial: "dispatch/activity_entry", locals: { event: self })
      end
    end

    def broadcast_updated
      each_broadcast_locale do |locale|
        Turbo::StreamsChannel.broadcast_replace_to(radio.broadcast_stream(locale), target: ActionView::RecordIdentifier.dom_id(self),
          partial: "dispatch/activity_entry", locals: { event: self })
      end
    end
end
