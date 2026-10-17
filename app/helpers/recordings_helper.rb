module RecordingsHelper
  def recording_direction_badge(recording)
    if recording.rx?
      tag.span(t("dispatch.activity.rx"), class: "badge bg-rx-soft font-semibold text-rx-ink")
    else
      tag.span(t("dispatch.activity.tx"), class: "badge bg-tx-soft font-semibold text-tx-ink")
    end
  end

  # Who talked (a reception's unit) or what keyed up a transmission
  def recording_source(recording)
    if recording.rx?
      return tag.span("—", class: "text-faint") if recording.unit_identifier.blank?

      unit = recording.unit
      label = unit_identifier_label(recording.decoder, recording.unit_identifier)
      unit ? safe_join([ tag.b(unit_name(unit), class: "text-ink-strong"), tag.span("(#{label})", class: "text-muted") ], " ") :
        tag.span("#{label} · #{t("dispatch.radio.unregistered")}", class: "text-warn-ink")
    else
      recording.radio ? link_source_label(recording.radio, recording.other_node) : (recording.other_node || t("dispatch.radio.local"))
    end
  end

  def recording_radio_name(recording)
    recording.radio&.name || t("dispatch.radio.node", node: recording.node)
  end

  def recording_duration(recording)
    seconds = recording.duration.round
    format("%d:%02d", seconds / 60, seconds % 60)
  end

  def recording_radio_options
    [ [ t("recordings.index.all_radios"), "" ] ] + Current.user.radios.ordered.map { |radio| [ radio.name, radio.id ] }
  end

  def recording_direction_options
    [ [ t("recordings.index.both"), "" ], [ t("recordings.index.rx"), "rx" ], [ t("recordings.index.tx"), "tx" ] ]
  end

  def recordings_page_link(filters, page, label)
    link_to label, recordings_path(filters.merge(page: page)), class: "btn btn-sm"
  end
end
